import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/models/commercial_activity.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/models/activity.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
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
        .read(firestoreServiceProvider)
        .getChats(widget.activity.id)
        .then((value) {
      setState(() {
        chats = value;
        admin = widget.activity.creator;
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
                      gradient: AppStyle.pinkGradient),
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
                  widget.activity.title,
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
                  height: 75, child: Activity.getSymbol(widget.activity)),
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
                    sentByMe: ref.read(userStateProvider.notifier).data.uid ==
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
        'sender': ref.read(userStateProvider.notifier).data.uid,
        'senderName': ref.read(userStateProvider.notifier).data.name!,
        'time': DateTime.now().millisecondsSinceEpoch,
      };
      ref
          .read(firestoreServiceProvider)
          .sendMessage(widget.activity.id, chatMessageMap);

      var receivers = await ref
          .read(firestoreServiceProvider)
          .fetchUsersByUids(widget.activity.participantsInfo.keys.toList());
      for (MiittiUser receiver in receivers) {
        if (receiver.uid == ref.read(userStateProvider.notifier).data.uid) continue;
        ref.read(notificationServiceProvider).sendMessageNotification(
            receiver.fcmToken,
            ref.read(userStateProvider.notifier).data.name!,
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
