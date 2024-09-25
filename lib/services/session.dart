
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/state/user.dart';

class Session with WidgetsBindingObserver {
  final Ref ref;

  Timestamp startTime;
  Timestamp? currentPageStartTime;
  String? currentPageName;
  Map<String, Duration> pageDurations;
  Map<String, int> actions;

  Session(this.ref)
      : startTime = Timestamp.now(),
        pageDurations = {},
        actions = {} {
    WidgetsBinding.instance.addObserver(this);
    ref.read(userStateProvider.notifier).sessionUpdateUserData(begin: true);
    // initPushNotifications();
  }

  // void initPushNotifications() {
  //   ref.read(notificationServiceProvider).init();
  //   ref.read(notificationServiceProvider).localNotiInit();
  // }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ref.read(firestoreServiceProvider).updateUser({'userStatus': Timestamp.now()});
    if (state == AppLifecycleState.resumed) {
        ref.read(userStateProvider.notifier).sessionUpdateUserData(begin: true);
      // endSession();
    } else if (state == AppLifecycleState.hidden || state == AppLifecycleState.detached || state == AppLifecycleState.paused) {
      ref.read(userStateProvider.notifier).sessionUpdateUserData(begin: false);
      // startTime = Timestamp.now();
    }
  }

  // //TODO: Call from navigation functions to track page changes
  // void startPage(String pageName) {
  //   endPage();
  //   currentPageStartTime = Timestamp.now();
  //   currentPageName = pageName;
  // }

  // void endPage() {
  //   if (currentPageStartTime != null && currentPageName != null) {
  //     final duration = Timestamp.now().millisecondsSinceEpoch -
  //         currentPageStartTime!.millisecondsSinceEpoch;
  //     pageDurations[currentPageName!] = Duration(milliseconds: duration);
  //   }
  // }

  // //TODO: Call from onPressed or onTap to track user actions
  // void addAction(String actionName) {
  //   if (actions.containsKey(actionName)) {
  //     actions[actionName] = actions[actionName]! + 1;
  //   } else {
  //     actions[actionName] = 1;
  //   }
  // }

  // void endSession() {
  //   // endPage();
  //   final duration = Timestamp.now().millisecondsSinceEpoch -
  //       startTime.millisecondsSinceEpoch;
  //   pageDurations['total'] = Duration(milliseconds: duration);
  //   //TODO: Save to Firestore
  // }
}