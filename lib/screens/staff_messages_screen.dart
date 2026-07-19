import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/chat_message.dart';
import '../providers/auth_provider.dart';
import '../providers/pharmacist_chat_provider.dart';

/// Staff "Patient Messages" inbox — one row per customer thread, tap
/// to open the full conversation and reply. Threads are grouped
/// client-side from the flat pharmacist_messages collection since
/// threadId == the customer's uid.
class StaffMessagesScreen extends StatelessWidget {
  const StaffMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.read<PharmacistChatProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Patient Messages')),
      body: SafeArea(
        child: StreamBuilder<List<ChatMessage>>(
          stream: chatProvider.threadsStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final all = snapshot.data!;
            if (all.isEmpty) {
              return Center(
                child: Text('No messages yet', style: TextStyle(color: Colors.grey.shade500)),
              );
            }

            // threadsStream() is already newest-first, so the first
            // message we see per threadId is the latest one. Separately
            // track the customer's own name (the latest message might
            // be a staff reply, not the customer).
            final latestByThread = <String, ChatMessage>{};
            final customerNameByThread = <String, String>{};
            for (final m in all) {
              latestByThread.putIfAbsent(m.threadId, () => m);
              if (!m.isStaff) {
                customerNameByThread.putIfAbsent(m.threadId, () => m.senderName);
              }
            }
            final threads = latestByThread.values.toList()
              ..sort((a, b) => b.sentAt.compareTo(a.sentAt));

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: threads.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final thread = threads[i];
                final customerName = customerNameByThread[thread.threadId] ?? 'Patient';
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StaffMessageThreadScreen(
                        threadId: thread.threadId,
                        customerName: customerName,
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderGrey),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.primaryNavy.withValues(alpha: 0.1),
                          child: const Icon(Icons.person_outline, color: AppTheme.primaryNavy),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(customerName, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(
                                thread.isStaff ? 'You: ${thread.text}' : thread.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Full thread view for one customer, staff side. Mirrors
/// AskPharmacistScreen's bubble UI but sent messages (isStaff: true)
/// render on the right instead.
class StaffMessageThreadScreen extends StatefulWidget {
  final String threadId;
  final String customerName;

  const StaffMessageThreadScreen({
    super.key,
    required this.threadId,
    required this.customerName,
  });

  @override
  State<StaffMessageThreadScreen> createState() => _StaffMessageThreadScreenState();
}

class _StaffMessageThreadScreenState extends State<StaffMessageThreadScreen> {
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
    final staffUser = context.read<AuthProvider>().currentUser;
    if (staffUser == null) return;
    _controller.clear();
    await context.read<PharmacistChatProvider>().sendMessage(
          threadId: widget.threadId,
          text: text,
          senderName: staffUser.name,
          isStaff: true,
        );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.read<PharmacistChatProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.customerName)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: chatProvider.messagesStream(widget.threadId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snapshot.data!;
                  _scrollToBottom();
                  if (messages.isEmpty) {
                    return Center(
                      child: Text('No messages yet', style: TextStyle(color: Colors.grey.shade500)),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, i) => _StaffBubble(message: messages[i]),
                  );
                },
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
                          hintText: 'Reply...',
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

class _StaffBubble extends StatelessWidget {
  final ChatMessage message;
  const _StaffBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    // Staff's own replies sit on the right; the customer's messages
    // sit on the left — the mirror image of the customer's screen.
    final isMine = message.isStaff;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMine ? AppTheme.primaryNavy : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: isMine ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}