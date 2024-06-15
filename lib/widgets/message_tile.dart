import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      margin: BubbleEdges.only(top: 10.h),
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
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            message,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Sora',
              fontSize: 18.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            time,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontFamily: 'Sora',
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }
}
