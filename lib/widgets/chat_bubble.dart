import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/chat_message.dart';
import '../core/theme/app_theme.dart';

/// Shared building blocks for the AI pharmacist chat (AiPharmacistScreen)
/// so it gets a WhatsApp-style timeline — date dividers, per-bubble
/// timestamps, long-press-to-copy, lightweight markdown for bot
/// replies — for free. The underlying data is already live via
/// Firestore .snapshots() in AiPharmacistProvider; this file is purely
/// presentation.

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
///
/// Long-pressing any bubble copies its text — a small but expected
/// "modern chatbot" affordance. Bot replies additionally get
/// lightweight markdown (bold, bullet lists) since Gemini often
/// formats answers that way.
class ChatBubble extends StatelessWidget {
  final String text;
  final DateTime sentAt;
  final bool isMine;
  final Color mineColor;
  final bool isBotReply;

  const ChatBubble({
    super.key,
    required this.text,
    required this.sentAt,
    required this.isMine,
    required this.mineColor,
    this.isBotReply = false,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message copied'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isMine ? Colors.white : Colors.black87;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _copyToClipboard(context),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              isBotReply
                  ? _MarkdownLiteText(text: text, color: textColor)
                  : Text(text, style: TextStyle(color: textColor, fontSize: 14.5)),
              const SizedBox(height: 3),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  chatTimeLabel(sentAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMine ? Colors.white.withValues(alpha: 0.7) : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimal markdown renderer for bot replies — just enough for the
/// formatting Gemini actually tends to produce (bold and bullet
/// lists), without pulling in a full markdown package/dependency.
class _MarkdownLiteText extends StatelessWidget {
  final String text;
  final Color color;
  const _MarkdownLiteText({required this.text, required this.color});

  List<TextSpan> _parseInlineBold(String line, TextStyle base) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    var last = 0;
    for (final match in regex.allMatches(line)) {
      if (match.start > last) {
        spans.add(TextSpan(text: line.substring(last, match.start), style: base));
      }
      spans.add(TextSpan(text: match.group(1), style: base.copyWith(fontWeight: FontWeight.w700)));
      last = match.end;
    }
    if (last < line.length) {
      spans.add(TextSpan(text: line.substring(last), style: base));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(color: color, fontSize: 14.5, height: 1.35);
    final widgets = <Widget>[];
    for (final rawLine in text.split('\n')) {
      final line = rawLine.trimRight();
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }
      final trimmedLeft = line.trimLeft();
      final isBullet = trimmedLeft.startsWith('- ') || trimmedLeft.startsWith('* ');
      final content = isBullet ? trimmedLeft.substring(2) : line;
      final spans = _parseInlineBold(content, baseStyle);
      if (isBullet) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('•  ', style: baseStyle),
              Flexible(child: RichText(text: TextSpan(children: spans))),
            ],
          ),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: RichText(text: TextSpan(children: spans)),
        ));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }
}

/// Builds the full scrollable timeline for a ListView's `children:` —
/// a date divider wherever the day changes, one bubble per message.
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
    widgets.add(ChatBubble(
      text: message.text,
      sentAt: message.sentAt,
      isMine: isMine(message),
      mineColor: mineColor,
      isBotReply: message.isBot,
    ));
  }
  return widgets;
}
