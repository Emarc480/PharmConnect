import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/pharmacist_chat_provider.dart';
import '../widgets/chat_bubble.dart';

/// "Ask a pharmacist" chat, customer side. Every customer has exactly
/// one thread (threadId == their uid) that any staff member can see
/// and reply to from the staff Messages inbox — live both ways via
/// PharmacistChatProvider's Firestore stream.
class AskPharmacistScreen extends StatefulWidget {
  const AskPharmacistScreen({super.key});

  @override
  State<AskPharmacistScreen> createState() => _AskPharmacistScreenState();
}

class _AskPharmacistScreenState extends State<AskPharmacistScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    _controller.clear();
    await context.read<PharmacistChatProvider>().sendMessage(
          threadId: user.uid,
          text: text,
          senderName: user.name,
          isStaff: false,
        );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<PharmacistChatProvider>();
    final messages = chat.myMessages;
    _scrollToBottom();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.inStockGreen,
              child: Icon(Icons.local_pharmacy_outlined, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ask a pharmacist', style: TextStyle(fontSize: 16)),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(color: AppTheme.inStockGreen, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text('Online', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: chat.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : chat.error != null
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline, color: Colors.grey.shade400, size: 32),
                                const SizedBox(height: 10),
                                Text(
                                  "Couldn't load your conversation. Check your connection and reopen this chat.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        )
                      : messages.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Ask about dosages, interactions, or anything about your medication. A pharmacist will reply here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                    )
                  : ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      children: buildChatTimeline(
                        messages: messages,
                        isMine: (m) => !m.isStaff,
                        mineColor: AppTheme.inStockGreen,
                      ),
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Type your question...',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.primaryNavy,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 18),
                        onPressed: _send,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}