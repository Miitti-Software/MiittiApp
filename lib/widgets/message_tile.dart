import 'package:flutter/material.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:bubble/bubble.dart';

class MessageTile extends StatelessWidget {
  final String message;
  final String sender;
  final String senderName;
  final bool sentByMe;
  final String time; // Add this line

  const MessageTile({
    super.key,
    required this.message,
    required this.sender,
    required this.senderName,
    required this.sentByMe,
    required this.time, // Add this line
  });

  @override
  Widget build(BuildContext context) {
    return Bubble(
      margin: const BubbleEdges.only(top: 10),
      alignment: sentByMe ? Alignment.topRight : Alignment.topLeft,
      nipWidth: 8,
      nipHeight: 24,
      nip: sentByMe ? BubbleNip.rightBottom : BubbleNip.leftBottom,
      color: sentByMe ? AppStyle.lightPurple : AppStyle.pink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            senderName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Sora',
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontFamily: 'Sora',
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
