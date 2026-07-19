import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';

/// "Ask a Pharmacist" messaging. Each customer has exactly one thread
/// (threadId == their uid). This provider auto-subscribes the signed
/// -in customer to their own thread (`myMessages`); staff use the raw
/// [threadsStream]/[messagesStream] with a StreamBuilder to browse and
/// reply to any customer's thread from the Messages inbox.
class PharmacistChatProvider extends ChangeNotifier {
  PharmacistChatProvider() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  List<ChatMessage> _myMessages = [];
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  List<ChatMessage> get myMessages => List.unmodifiable(_myMessages);

  void _onAuthChanged(User? user) {
    _sub?.cancel();
    if (user == null) {
      _myMessages = [];
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _sub = _db
        .collection('pharmacist_messages')
        .where('threadId', isEqualTo: user.uid)
        .orderBy('sentAtMs')
        .snapshots()
        .listen(_onSnapshot, onError: (_) {});
  }

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _myMessages = snapshot.docs.map((d) => ChatMessage.fromMap(d.id, d.data())).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage({
    required String threadId,
    required String text,
    required String senderName,
    required bool isStaff,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Cannot send a message while signed out.');
    if (text.trim().isEmpty) return;
    final ref = _db.collection('pharmacist_messages').doc();
    final message = ChatMessage(
      id: ref.id,
      threadId: threadId,
      senderId: uid,
      senderName: senderName,
      isStaff: isStaff,
      text: text.trim(),
      sentAt: DateTime.now(),
    );
    await ref.set(message.toMap());
  }

  /// Raw per-thread stream for the staff-side chat detail screen.
  Stream<List<ChatMessage>> messagesStream(String threadId) {
    return _db
        .collection('pharmacist_messages')
        .where('threadId', isEqualTo: threadId)
        .orderBy('sentAtMs')
        .snapshots()
        .map((s) => s.docs.map((d) => ChatMessage.fromMap(d.id, d.data())).toList());
  }

  /// All messages across every thread, newest first — the staff
  /// Messages inbox groups these client-side into one row per thread.
  Stream<List<ChatMessage>> threadsStream() {
    return _db
        .collection('pharmacist_messages')
        .orderBy('sentAtMs', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ChatMessage.fromMap(d.id, d.data())).toList());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}