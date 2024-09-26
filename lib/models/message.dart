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

  factory Message.fromFirestore(Map<String, dynamic> data) {
    return Message(
      message: data['message'],
      senderId: data['senderId'],
      senderName: data['senderName'],
      timestamp: data['timestamp']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': timestamp,
    };
  }
}