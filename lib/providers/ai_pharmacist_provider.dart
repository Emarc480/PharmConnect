import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../services/gemini_service.dart';

/// "Ask a Pharmacist" chat, now answered instantly by an AI (Gemini)
/// instead of waiting for a human pharmacist to reply.
///
/// Each customer has exactly one thread (threadId == their uid), stored
/// in Firestore purely so the conversation survives app restarts /
/// device switches. There is no staff side any more — every message a
/// customer sends gets an automatic bot reply appended right after it.
class AiPharmacistProvider extends ChangeNotifier {
  AiPharmacistProvider() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  static const String _botSenderId = 'ai-bot';
  static const String _botSenderName = 'PharmBot';

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  List<ChatMessage> _myMessages = [];
  bool _isLoading = true;
  bool _isBotTyping = false;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isBotTyping => _isBotTyping;
  String? get error => _error;
  List<ChatMessage> get myMessages => List.unmodifiable(_myMessages);

  /// True when the last message is a bot reply that can be redone —
  /// i.e. there's something to regenerate and we're not already
  /// waiting on Gemini.
  bool get canRegenerate =>
      !_isBotTyping && _myMessages.isNotEmpty && _myMessages.last.isBot;

  void _onAuthChanged(User? user) {
    _sub?.cancel();
    if (user == null) {
      _myMessages = [];
      _isLoading = false;
      _isBotTyping = false;
      _error = null;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    _sub = _db
        .collection('ai_chat_messages')
        .where('threadId', isEqualTo: user.uid)
        .orderBy('sentAtMs')
        .snapshots()
        .listen(_onSnapshot, onError: _onStreamError);
  }

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _myMessages = snapshot.docs.map((d) => ChatMessage.fromMap(d.id, d.data())).toList();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  void _onStreamError(Object e) {
    // Surface it instead of hanging silently forever (e.g. a missing
    // Firestore composite index shows up here as failed-precondition).
    _isLoading = false;
    _error = e.toString();
    notifyListeners();
  }

  /// Sends the customer's message, then immediately asks Gemini for a
  /// reply and appends it as a bot message — no human in the loop.
  /// [customerContext] (optional) is a live summary of the customer's
  /// own orders/reminders/prescriptions — see CustomerContextBuilder.
  Future<void> sendMessage({
    required String text,
    required String senderName,
    String? customerContext,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Cannot send a message while signed out.');
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final historyBeforeThisMessage = List<ChatMessage>.from(_myMessages);

    await _addMessage(
      threadId: uid,
      senderId: uid,
      senderName: senderName,
      isBot: false,
      text: trimmed,
    );

    _isBotTyping = true;
    notifyListeners();
    try {
      final botReply = await GeminiService.reply(
        history: historyBeforeThisMessage,
        userMessage: trimmed,
        customerContext: customerContext,
      );
      await _addMessage(
        threadId: uid,
        senderId: _botSenderId,
        senderName: _botSenderName,
        isBot: true,
        text: botReply,
      );
    } catch (e) {
      await _addMessage(
        threadId: uid,
        senderId: _botSenderId,
        senderName: _botSenderName,
        isBot: true,
        text: "Sorry, I couldn't get a response just now "
            "(${_friendlyError(e)}). Please try again in a moment.",
      );
    } finally {
      _isBotTyping = false;
      notifyListeners();
    }
  }

  /// Redoes the last bot reply — deletes it and asks Gemini again from
  /// the same customer message, in case the first answer wasn't
  /// helpful. No-op if there's nothing to regenerate.
  Future<void> regenerateLastReply({String? customerContext}) async {
    if (!canRegenerate) return;

    final lastBotMessage = _myMessages.last;
    final withoutLastBot = _myMessages.sublist(0, _myMessages.length - 1);
    if (withoutLastBot.isEmpty || withoutLastBot.last.isBot) {
      return; // Nothing to regenerate from (shouldn't normally happen).
    }
    final prompt = withoutLastBot.last;
    final historyBeforePrompt = withoutLastBot.sublist(0, withoutLastBot.length - 1);

    _isBotTyping = true;
    notifyListeners();
    try {
      await _db.collection('ai_chat_messages').doc(lastBotMessage.id).delete();
      final botReply = await GeminiService.reply(
        history: historyBeforePrompt,
        userMessage: prompt.text,
        customerContext: customerContext,
      );
      await _addMessage(
        threadId: prompt.threadId,
        senderId: _botSenderId,
        senderName: _botSenderName,
        isBot: true,
        text: botReply,
      );
    } catch (e) {
      await _addMessage(
        threadId: prompt.threadId,
        senderId: _botSenderId,
        senderName: _botSenderName,
        isBot: true,
        text: "Sorry, I couldn't regenerate that response "
            "(${_friendlyError(e)}). Please try again in a moment.",
      );
    } finally {
      _isBotTyping = false;
      notifyListeners();
    }
  }

  /// Starts a fresh conversation by wiping this customer's thread.
  Future<void> clearConversation() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snapshot = await _db
        .collection('ai_chat_messages')
        .where('threadId', isEqualTo: uid)
        .get();
    if (snapshot.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  String _friendlyError(Object e) {
    if (e is StateError) return 'AI not configured';
    return 'connection issue';
  }

  Future<void> _addMessage({
    required String threadId,
    required String senderId,
    required String senderName,
    required bool isBot,
    required String text,
  }) async {
    final ref = _db.collection('ai_chat_messages').doc();
    final message = ChatMessage(
      id: ref.id,
      threadId: threadId,
      senderId: senderId,
      senderName: senderName,
      isBot: isBot,
      text: text,
      sentAt: DateTime.now(),
    );
    await ref.set(message.toMap());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
