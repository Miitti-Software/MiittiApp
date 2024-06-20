import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/services/providers.dart';

class SessionNotifier with WidgetsBindingObserver {
  final Ref ref;

  Timestamp startTime;
  Timestamp? currentPageStartTime;
  String? currentPageName;
  Map<String, Duration> pageDurations;
  Map<String, int> actions;

  SessionNotifier(this.ref)
      : startTime = Timestamp.now(),
        pageDurations = {},
        actions = {} {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(firestoreService).updateUser({'userStatus': Timestamp.now()});
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      endSession();
    }
  }

  void startPage(String pageName) {
    currentPageStartTime = Timestamp.now();
    currentPageName = pageName;
  }

  void endPage() {
    if (currentPageStartTime != null && currentPageName != null) {
      final duration = Timestamp.now().millisecondsSinceEpoch -
          currentPageStartTime!.millisecondsSinceEpoch;
      pageDurations[currentPageName!] = Duration(milliseconds: duration);
    }
  }

  void addAction(String actionName) {
    if (actions.containsKey(actionName)) {
      actions[actionName] = actions[actionName]! + 1;
    } else {
      actions[actionName] = 1;
    }
  }

  void endSession() {
    final duration = Timestamp.now().millisecondsSinceEpoch -
        startTime.millisecondsSinceEpoch;
    pageDurations['total'] = Duration(milliseconds: duration);
    // Save to Firestore
  }
}
