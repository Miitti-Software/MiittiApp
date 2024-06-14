import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/models/person_activity.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/widgets/message_tile.dart';
import 'package:miitti_app/services/auth_provider.dart';
import 'package:miitti_app/functions/push_notifications.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:provider/provider.dart';

import 'package:intl/intl.dart'; // Add this line for the DateFormat class

//TODO: New UI

class ChatPage extends StatefulWidget {
  const ChatPage({required this.activity, super.key});

  final PersonActivity activity;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  Stream<QuerySnapshot>? chats;
  late TextEditingController messageController;
  late FocusNode messageChatFocus;
  String admin = "";

  @override
  void initState() {
    super.initState();
    messageController = TextEditingController();
    messageChatFocus = FocusNode();
    getChat();
  }

  @override
  void dispose() {
    messageController.dispose();
    messageChatFocus.dispose();

    super.dispose();
  }

  getChat() async {
    final ap = Provider.of<AuthProvider>(context, listen: false);

    await ap.getChats(widget.activity.activityUid).then((value) {
      setState(() {
        chats = value;
        admin = widget.activity.admin;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(
                      context,
                    );
                  },
                  child: Container(
                    height: 55.w,
                    width: 55.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [
                          AppStyle.lightRedColor,
                          AppStyle.orangeColor,
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 30.r,
                    ),
                  ),
                ),
                SizedBox(
                  width: 5.w,
                ),
                Expanded(
                  child: Text(
                    widget.activity.activityTitle,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Sora',
                    ),
                  ),
                ),
                SizedBox(
                  height: 75.w,
                  child: Image.asset(
                    'images/${widget.activity.activityCategory.toLowerCase()}.png',
                  ),
                ),
              ],
            ),
            Expanded(child: chatMessages()),
            getOurTextField(
              myController: messageController,
              myPadding: EdgeInsets.all(8.0.w),
              myFocusNode: messageChatFocus,
              myOnTap: () {
                if (messageChatFocus.hasFocus) {
                  messageChatFocus.unfocus();
                }
              },
              mySuffixIcon: GestureDetector(
                onTap: () {
                  sendMessage();
                  if (messageChatFocus.hasFocus) {
                    messageChatFocus.unfocus();
                  }
                },
                child: Container(
                  height: 50.w,
                  width: 50.w,
                  margin: EdgeInsets.all(10.0.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppStyle.lightRedColor,
                        AppStyle.orangeColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              myKeyboardType: TextInputType.multiline,
              maxLines: 8,
              minLines: 1,
              maxLenght: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget chatMessages() {
    final ap = Provider.of<AuthProvider>(context, listen: false);

    return StreamBuilder(
      stream: chats,
      builder: (context, AsyncSnapshot snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                itemCount: snapshot.data.docs.length,
                reverse: true,
                itemBuilder: (context, index) {
                  return MessageTile(
                    message: snapshot.data.docs[index]['message'],
                    sender: snapshot.data.docs[index]['sender'],
                    senderName: snapshot.data.docs[index]['senderName'],
                    sentByMe: ap.uid == snapshot.data.docs[index]['sender'],
                    time: DateFormat('HH:mm').format(
                      DateTime.fromMillisecondsSinceEpoch(
                        snapshot.data.docs[index]['time'],
                      ),
                    ),
                  );
                },
              )
            : Container();
      },
    );
  }

  void sendMessage() async {
    final ap = Provider.of<AuthProvider>(context, listen: false);

    if (messageController.text.isNotEmpty) {
      Map<String, dynamic> chatMessageMap = {
        'message': messageController.text,
        'sender': ap.uid,
        'senderName': ap.miittiUser.userName,
        'time': DateTime.now().millisecondsSinceEpoch,
      };
      ap.sendMessage(widget.activity.activityUid, chatMessageMap);

      var receivers = await ap.fetchUsersByUids(widget.activity.participants);
      for (MiittiUser receiver in receivers) {
        if (receiver.uid == ap.uid) continue;
        PushNotifications.sendMessageNotification(receiver.fcmToken,
            ap.miittiUser.userName, widget.activity, messageController.text);
      }

      setState(() {
        messageController.clear();
      });
    }
  }

  String weekdayToFinnish(String weekday) {
    switch (weekday) {
      case 'Monday':
        return 'Maanantai';
      case 'Tuesday':
        return 'Tiistai';
      case 'Wednesday':
        return 'Keskiviikko';
      case 'Thursday':
        return 'Torstai';
      case 'Friday':
        return 'Perjantai';
      case 'Saturday':
        return 'Launantai';
      case 'Sunday':
        return 'Sunnuntai';
      default:
        return 'Tänään';
    }
  }
}
