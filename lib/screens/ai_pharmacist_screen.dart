import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/ai_pharmacist_provider.dart';
import '../providers/order_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/prescription_provider.dart';
import '../services/customer_context_builder.dart';
import '../widgets/chat_bubble.dart';

/// "Ask a pharmacist" chat, customer side — answered instantly by an
/// AI assistant (Gemini) instead of waiting for a human pharmacist.
/// Also aware of the customer's own orders/reminders/prescriptions so
/// it can answer specific questions, not just generic ones.
class AiPharmacistScreen extends StatefulWidget {
  const AiPharmacistScreen({super.key});

  @override
  State<AiPharmacistScreen> createState() => _AiPharmacistScreenState();
}

class _AiPharmacistScreenState extends State<AiPharmacistScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  bool _showScrollToBottom = false;

  static const List<String> _defaultSuggestions = [
    'What are common side effects?',
    'Check drug interactions',
    'How should I store my medication?',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final distanceFromBottom =
        _scrollController.position.maxScrollExtent - _scrollController.position.pixels;
    final shouldShow = distanceFromBottom > 200;
    if (shouldShow != _showScrollToBottom) {
      setState(() => _showScrollToBottom = shouldShow);
    }
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  /// Live summary of the customer's own orders/reminders/prescriptions,
  /// handed to Gemini so it can answer specific questions like
  /// "where's my order?" — see CustomerContextBuilder.
  String _buildCustomerContext() {
    final myOrders = context.read<OrderProvider>().myOrders;
    final reminders = context.read<ReminderProvider>().reminders;
    final myPrescriptions = context.read<PrescriptionProvider>().myRequests;
    return CustomerContextBuilder.build(
      myOrders: myOrders,
      reminders: reminders,
      myPrescriptions: myPrescriptions,
    );
  }

  /// Contextual quick-reply suggestions — generic pharmacy questions,
  /// plus one tailored to the customer's own data when relevant.
  List<String> _suggestions() {
    final suggestions = <String>[];
    if (context.read<OrderProvider>().myOrders.isNotEmpty) {
      suggestions.add("Where's my order?");
    }
    if (context.read<ReminderProvider>().reminders.isNotEmpty) {
      suggestions.add("When's my next dose?");
    }
    if (context.read<PrescriptionProvider>().myRequests.isNotEmpty) {
      suggestions.add('Check my prescription status');
    }
    suggestions.addAll(_defaultSuggestions);
    return suggestions.take(4).toList();
  }

  Future<void> _sendText(String text) async {
    if (text.trim().isEmpty || _sending) return;
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    _controller.clear();
    setState(() => _sending = true);
    try {
      await context.read<AiPharmacistProvider>().sendMessage(
            text: text,
            senderName: user.name,
            customerContext: _buildCustomerContext(),
          );
      _scrollToBottom();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't send that message. Please try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _send() => _sendText(_controller.text);

  Future<void> _regenerate() async {
    try {
      await context.read<AiPharmacistProvider>().regenerateLastReply(
            customerContext: _buildCustomerContext(),
          );
      _scrollToBottom();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't regenerate that response.")),
        );
      }
    }
  }

  Future<void> _confirmNewChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a new chat?'),
        content: const Text('This clears your current conversation with PharmBot. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start new chat'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AiPharmacistProvider>().clearConversation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<AiPharmacistProvider>();
    final messages = chat.myMessages;
    if (!_showScrollToBottom) _scrollToBottom(animate: false);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.inStockGreen,
              child: Icon(Icons.smart_toy_outlined, color: Colors.white, size: 18),
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
                    Text(
                      chat.isBotTyping ? 'Typing...' : 'AI • Instant replies',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'New chat',
            icon: const Icon(Icons.refresh),
            onPressed: messages.isEmpty ? null : _confirmNewChat,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppTheme.inStockGreen.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'PharmBot is an AI assistant, not a licensed pharmacist. For '
                'emergencies or specific prescription questions, contact the '
                'pharmacy directly.',
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  chat.isLoading
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
                              ? _EmptyState(onSuggestionTap: _sendText, suggestions: _suggestions())
                              : ListView(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(16),
                                  children: [
                                    ...buildChatTimeline(
                                      messages: messages,
                                      isMine: (m) => !m.isBot,
                                      mineColor: AppTheme.inStockGreen,
                                    ),
                                    if (chat.isBotTyping) const _TypingBubble(),
                                    if (chat.canRegenerate)
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton.icon(
                                          onPressed: _regenerate,
                                          icon: const Icon(Icons.refresh, size: 16),
                                          label: const Text('Regenerate response'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.grey.shade700,
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(0, 32),
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                  if (_showScrollToBottom)
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: FloatingActionButton.small(
                        heroTag: 'scrollToBottom',
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryNavy,
                        elevation: 2,
                        onPressed: () => _scrollToBottom(),
                        child: const Icon(Icons.arrow_downward),
                      ),
                    ),
                ],
              ),
            ),
            if (messages.isNotEmpty && !chat.isBotTyping)
              _SuggestionChipsRow(suggestions: _suggestions(), onTap: _sendText),
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
                      child: _sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : IconButton(
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

/// Empty-conversation state with bigger, tappable suggestion cards —
/// the "prompt starter" pattern from modern chatbot apps.
class _EmptyState extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onSuggestionTap;
  const _EmptyState({required this.suggestions, required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy_outlined, color: Colors.grey.shade400, size: 40),
            const SizedBox(height: 12),
            Text(
              'Ask about dosages, interactions, or anything about your '
              'medication. PharmBot replies instantly.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: suggestions
                  .map((s) => ActionChip(
                        label: Text(s),
                        onPressed: () => onSuggestionTap(s),
                        backgroundColor: Colors.grey.shade100,
                        side: BorderSide(color: Colors.grey.shade300),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Slim horizontal row of follow-up suggestion chips pinned above the
/// composer once a conversation is underway.
class _SuggestionChipsRow extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onTap;
  const _SuggestionChipsRow({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => ActionChip(
          label: Text(suggestions[i], style: const TextStyle(fontSize: 12.5)),
          onPressed: () => onTap(suggestions[i]),
          backgroundColor: Colors.grey.shade100,
          side: BorderSide(color: Colors.grey.shade300),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

/// Small "PharmBot is typing..." indicator shown while waiting on Gemini.
class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: SizedBox(
          width: 30,
          height: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              3,
              (i) => CircleAvatar(radius: 3, backgroundColor: Colors.grey.shade500),
            ),
          ),
        ),
      ),
    );
  }
}
