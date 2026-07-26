/// One message in a customer's "Ask a Pharmacist" AI chat thread.
/// Threads are keyed by the customer's uid (threadId == customerId),
/// so each customer has exactly one running conversation with the bot.
class ChatMessage {
  final String id;
  final String threadId;
  final String senderId;
  final String senderName;
  final bool isBot;
  final String text;
  final DateTime sentAt;

  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.senderName,
    required this.isBot,
    required this.text,
    required this.sentAt,
  });

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessage(
      id: id,
      threadId: (map['threadId'] as String?) ?? '',
      senderId: (map['senderId'] as String?) ?? '',
      senderName: (map['senderName'] as String?) ?? '',
      isBot: (map['isBot'] as bool?) ?? false,
      text: (map['text'] as String?) ?? '',
      sentAt: DateTime.fromMillisecondsSinceEpoch(
        (map['sentAtMs'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'threadId': threadId,
      'senderId': senderId,
      'senderName': senderName,
      'isBot': isBot,
      'text': text,
      'sentAtMs': sentAt.millisecondsSinceEpoch,
    };
  }
}
