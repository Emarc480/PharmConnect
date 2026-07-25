import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../core/theme/app_theme.dart';

/// Shared building blocks for both chat screens (customer
/// AskPharmacistScreen and staff StaffMessageThreadScreen) so a
/// WhatsApp-style timeline — date dividers, per-bubble timestamps —
/// looks and behaves identically on both sides. The underlying data
/// is already live via Firestore .snapshots() in
/// PharmacistChatProvider; this file is purely presentation.

String chatDateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String chatTimeLabel(DateTime time) {
  final hour24 = time.hour;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = hour24 < 12 ? 'AM' : 'PM';
  return '$hour12:$minute $period';
}

/// Centered pill divider between days — "Today" / "Yesterday" /
/// "12 Jul 2026" — the standard chat-app date-separator pattern.
class ChatDateDivider extends StatelessWidget {
  final DateTime date;
  const ChatDateDivider({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.navBarSurface(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            chatDateLabel(date),
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
          ),
        ),
      ),
    );
  }
}

/// One bubble with the timestamp tucked into its own bottom-right
/// corner rather than a separate row — this is what actually makes it
/// read as a real chat app instead of a list of colored boxes.
class ChatBubble extends StatelessWidget {
  final String text;
  final DateTime sentAt;
  final bool isMine;
  final Color mineColor;

  const ChatBubble({
    super.key,
    required this.text,
    required this.sentAt,
    required this.isMine,
    required this.mineColor,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.fromLTRB(14, 9, 10, 7),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
        decoration: BoxDecoration(
          color: isMine ? mineColor : AppTheme.navBarSurface(context),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: TextStyle(color: isMine ? Colors.white : Colors.black87, fontSize: 14.5)),
            const SizedBox(height: 3),
            Text(
              chatTimeLabel(sentAt),
              style: TextStyle(
                fontSize: 10,
                color: isMine ? Colors.white : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Builds the full scrollable timeline for a ListView's `children:` —
/// a date divider wherever the day changes, one bubble per message.
/// Both chat screens call this so their timelines match exactly.
List<Widget> buildChatTimeline({
  required List<ChatMessage> messages,
  required bool Function(ChatMessage message) isMine,
  required Color mineColor,
}) {
  final widgets = <Widget>[];
  DateTime? lastDay;
  for (final message in messages) {
    final day = DateTime(message.sentAt.year, message.sentAt.month, message.sentAt.day);
    if (lastDay == null || day != lastDay) {
      widgets.add(ChatDateDivider(date: message.sentAt));
      lastDay = day;
    }
    widgets.add(ChatBubble(text: message.text, sentAt: message.sentAt, isMine: isMine(message), mineColor: mineColor));
  }
  return widgets;
}