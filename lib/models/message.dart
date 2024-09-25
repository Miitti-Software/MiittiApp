class Message {
  final String message;
  final String senderId;
  final String senderName;
  final DateTime timestamp;

  Message({
    required this.message,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
  });
}