import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/models/person_activity.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/widgets/message_tile.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:miitti_app/widgets/safe_scaffold.dart';

import 'package:intl/intl.dart'; // Add this line for the DateFormat class

//TODO: New UI

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({required this.activity, super.key});

  final PersonActivity activity;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
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
        .read(firestoreServiceProvider)
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
                  height: 55,
                  width: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [
                        AppStyle.red,
                        AppStyle.pink,
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(
                width: 5,
              ),
              Expanded(
                child: Text(
                  widget.activity.activityTitle,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Sora',
                  ),
                ),
              ),
              SizedBox(
                height: 75,
                child: Image.asset(
                  'images/${widget.activity.activityCategory.toLowerCase()}.png',
                ),
              ),
            ],
          ),
          Expanded(child: chatMessages()),
          getOurTextField(
            myController: messageController,
            myPadding: const EdgeInsets.all(8.0),
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
                height: 50,
                width: 50,
                margin: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppStyle.red,
                      AppStyle.pink,
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
                    sentByMe: ref.read(authServiceProvider).uid ==
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
        'sender': ref.read(authServiceProvider).uid,
        'senderName': ref.read(firestoreServiceProvider).miittiUser!.name,
        'time': DateTime.now().millisecondsSinceEpoch,
      };
      ref
          .read(firestoreServiceProvider)
          .sendMessage(widget.activity.activityUid, chatMessageMap);

      var receivers = await ref
          .read(firestoreServiceProvider)
          .fetchUsersByUids(widget.activity.participants.toList());
      for (MiittiUser receiver in receivers) {
        if (receiver.uid == ref.read(firestoreServiceProvider).uid) continue;
        ref.read(notificationServiceProvider).sendMessageNotification(
            receiver.fcmToken,
            ref.read(firestoreServiceProvider).miittiUser!.name,
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
