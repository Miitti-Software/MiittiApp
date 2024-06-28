import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miitti_app/models/commercial_activity.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/models/activity.dart';
import 'package:miitti_app/services/providers.dart';
import 'package:miitti_app/widgets/message_tile.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:miitti_app/widgets/safe_scaffold.dart';

import 'package:intl/intl.dart'; // Add this line for the DateFormat class

class ComChatPage extends ConsumerStatefulWidget {
  const ComChatPage({required this.activity, super.key});

  final CommercialActivity activity;

  @override
  ConsumerState<ComChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ComChatPage> {
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
    await ref
        .read(firestoreService)
        .getChats(widget.activity.activityUid)
        .then((value) {
      setState(() {
        chats = value;
        admin = widget.activity.admin;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeScaffold(
      Column(
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
                      gradient: AppStyle.pinkGradient),
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
                  height: 75.w, child: Activity.getSymbol(widget.activity)),
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
                  gradient: AppStyle.pinkGradient,
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
    );
  }

  Widget chatMessages() {
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
                    sentByMe: ref.read(authService).uid ==
                        snapshot.data.docs[index]['sender'],
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
    if (messageController.text.isNotEmpty) {
      Map<String, dynamic> chatMessageMap = {
        'message': messageController.text,
        'sender': ref.read(authService).uid,
        'senderName': ref.read(firestoreService).miittiUser!.userName,
        'time': DateTime.now().millisecondsSinceEpoch,
      };
      ref
          .read(firestoreService)
          .sendMessage(widget.activity.activityUid, chatMessageMap);

      var receivers = await ref
          .read(firestoreService)
          .fetchUsersByUids(widget.activity.participants.toList());
      for (MiittiUser receiver in receivers) {
        if (receiver.uid == ref.read(authService).uid) continue;
        ref.read(notificationService).sendMessageNotification(
            receiver.fcmToken,
            ref.read(firestoreService).miittiUser!.userName,
            widget.activity,
            messageController.text);
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
