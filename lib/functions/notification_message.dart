import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/screens/activity_details_page.dart';
import 'package:miitti_app/screens/chat_page.dart';
import 'package:miitti_app/screens/commercialScreens/comchat_page.dart';
import 'package:miitti_app/models/commercial_activity.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/models/person_activity.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/screens/index_page.dart';
import 'package:miitti_app/screens/user_profile_edit_screen.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'dart:convert';


class NotificationMessage extends ConsumerStatefulWidget {
  const NotificationMessage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _NotificationMessageState();
}

class _NotificationMessageState extends ConsumerState<NotificationMessage> {
  @override
  Widget build(BuildContext context) {
    final data = ModalRoute.of(context)!.settings.arguments;
    Map<String, dynamic> payload = {};

    if (data is RemoteMessage) {
      payload = data.data;
      debugPrint("RemoteMessage opened");
    }

    if (data is NotificationResponse) {
      payload = jsonDecode(data.payload!);
      debugPrint("Notification response opened");
    }

    //Navigate insted of creating here
    getPage(payload, context).then((page) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => pushReplacement(context, page));
    });

    return const Scaffold(
        backgroundColor: AppStyle.black,
        body: Center(
          child: CircularProgressIndicator(),
        ));
  }

  Future<Widget> getPage(
      Map<String, dynamic> payload, BuildContext context) async {
    //Open activity page
    try {
      if (payload.containsKey("type")) {
        switch (payload["type"]) {
          case ("invite"):
            debugPrint("Invite clicked ${payload["myData"]}");
            PersonActivity activity = await ref
                .read(firestoreServiceProvider)
                .getSingleActivity(payload["myData"]) as PersonActivity;
            return ActivityDetailsPage(myActivity: activity);

          case ("request"):
            debugPrint("Request clicked ${payload["myData"]}");
            MiittiUser? user =
                await ref.read(firestoreServiceProvider).getUser(payload["myData"]);
            if (user != null) {
              return UserProfileEditScreen(user: user);
            } else {
              if (context.mounted) {
                showSnackBar(context, "Käyttäjää ei löytynyt", AppStyle.red);
              }
              return const IndexPage();
            }

          case ("accept"):
            debugPrint("Accept clicked ${payload["myData"]}");
            PersonActivity activity = await ref
                .read(firestoreServiceProvider)
                .getSingleActivity(payload["myData"]) as PersonActivity;
            return ActivityDetailsPage(myActivity: activity);

          case ("message"):
            debugPrint("Message clicked ${payload["myData"]}");
            MiittiActivity activity = await ref
                .read(firestoreServiceProvider)
                .getSingleActivity(payload["myData"]);
            if (activity is PersonActivity) {
              return ChatPage(activity: activity);
            } else {
              return ComChatPage(activity: activity as CommercialActivity);
            }
        }
        debugPrint("Type didn't match: ${payload["type"].toString()}");
      } else {
        debugPrint("Payload doesn't include that type");
      }

      return const IndexPage();
    } catch (e) {
      debugPrint("Error: $e");
      return const IndexPage();
    }
  }
}
