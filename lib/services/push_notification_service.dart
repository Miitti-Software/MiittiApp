import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/models/user_created_activity.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/main.dart';
import 'package:miitti_app/services/firestore_service.dart';
import 'package:miitti_app/services/remote_config_service.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:miitti_app/state/user.dart';
import 'dart:convert';

import 'package:permission_handler/permission_handler.dart';

class PushNotificationService {
  final Ref ref;
  final _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  PushNotificationService(this.ref);

  Future<bool> checkPermission() async {
    return await Permission.notification.isGranted;
  }

  Future initialize() async {
    //on background notification tapped
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.notification != null) {
        debugPrint("Background notification tapped");
        navigatorKey.currentState!
            .pushNamed("/notificationmessage", arguments: message);
      }
    });

    //Request notification permission
    await _firebaseMessaging.requestPermission(provisional: true);

    if (Platform.isIOS) {
      await _firebaseMessaging.getAPNSToken();
      await Future.delayed(const Duration(seconds: 1));
    }

    //get the device FCM(Firebase Cloud Messaging) token
    final token = await _firebaseMessaging.getToken();
    debugPrint("###### PRINT DEVICE TOKEN TO USE FOR PUSH NOTIFCIATION ######");
    debugPrint(token);
    debugPrint("############################################################");

    //Save token to user data(needed to access other users tokens in code)
    if (ref.read(userStateProvider).data.fcmToken != token && token != null) {
      ref.read(userStateProvider).data.setFcmToken(token);
      ref.read(userStateProvider.notifier).updateUserData();
    }

    _firebaseMessaging.onTokenRefresh
      .listen((fcmToken) {
        ref.read(userStateProvider).data.setFcmToken(fcmToken);
        ref.read(userStateProvider.notifier).updateUserData();
        // Note: This callback is fired at each app startup and whenever a new
        // token is generated.
      })
      .onError((err) {
        // Error getting token.
        debugPrint("Error getting token: $err");
      });

      localNotiInit();
  }

  Future<bool> requestPermission(bool requestEvenDenied) async {
    bool permanentlyDenied = await Permission.notification.isPermanentlyDenied;
    if (permanentlyDenied && requestEvenDenied) {
      await openAppSettings();
      return await Permission.notification.isGranted;
    } else {
      return await Permission.notification.request().isGranted;
    }
  }

  static Future firebaseBackgroundMessage(RemoteMessage message) async {
    if (message.notification != null) {
      String? title = message.notification?.title;
      debugPrint("Notification received $title");
    }
  }

  // initalize local notifications
  Future localNotiInit() async {
    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_stat_name');
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      onDidReceiveLocalNotification: (id, title, body, payload) {},
    );
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin);
    _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onNotificationTap,
        onDidReceiveBackgroundNotificationResponse: onNotificationTap);
  }

  void listenForeground() {
    // to handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      String payloadData = jsonEncode(message.data);
      debugPrint("Got a message in foreground");
      if (message.notification != null) {
        showSimpleNotification(
          title: message.notification!.title!,
          body: message.notification!.body!,
          payload: payloadData 
        );
      }
    });
  }

  // Send in the user's first language if it is available, otherwise send in English

  void listenTerminated() async {
    // for handling in terminated state
    final RemoteMessage? message =
        await FirebaseMessaging.instance.getInitialMessage();

    if (message != null) {
      debugPrint("Launched from terminated state");
      Future.delayed(const Duration(seconds: 2), () {
        navigatorKey.currentState!
            .pushNamed("/notificationmessage", arguments: message);
      });
    }
  }

  // on tap local notification in foreground
  static void onNotificationTap(NotificationResponse notificationResponse) {
    notificationResponse.payload;
    navigatorKey.currentState!
        .pushNamed("/notificationmessage", arguments: notificationResponse);
  }

  // show a simple notification
  Future showSimpleNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    final config = ref.read(remoteConfigServiceProvider);
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          config.get<String>('generic-channel-id'), 
          config.get<String>('generic-channel-name'),
          channelDescription: config.get<String>('generic-channel-description'),
          importance: Importance.max,
          priority: Priority.high,
          ticker: config.get<String>('generic-channel-description'));
    NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    await _flutterLocalNotificationsPlugin
        .show(0, title, body, notificationDetails, payload: payload);
  }

  void sendInviteNotification(MiittiUser current, MiittiUser receiver, UserCreatedActivity activity) async {
    final config = ref.read(remoteConfigServiceProvider);
    sendNotification(
      receiver.fcmToken,
      config.get<String>('invite-notification-title'),
      "${current.name} ${config.get<String>('invite-notification-body')} ${activity.title}",
      config.get<String>('invite-notification-type'),
      activity.id,
    );
  }

  Future sendRequestNotification(UserCreatedActivity activity) async {
    FirestoreService firestore = ref.read(firestoreServiceProvider);
    final config = ref.read(remoteConfigServiceProvider);
    UserStateData user = ref.read(userStateProvider);
    MiittiUser? admin = await firestore.getUser(activity.creator);
    if (admin != null) {
      sendNotification(
        admin.fcmToken,
        config.get<String>('join-request-notification-title'),
        "${user.data.name} ${config.get<String>('join-request-notification-body')} ${activity.title}",
        config.get<String>('join-request-notification-type'),
        user.data.uid!,
      );
    } else {
      debugPrint("Couldn't find admin to send request notification to.");
    }
  }

  Future sendJoinNotification(UserCreatedActivity activity) async {
    FirestoreService firestore = ref.read(firestoreServiceProvider);
    final config = ref.read(remoteConfigServiceProvider);
    UserStateData user = ref.read(userStateProvider);
    MiittiUser? activityCreator = await firestore.fetchUser(activity.creator);
    if (activityCreator != null) {
      sendNotification(
        activityCreator.fcmToken,
        config.get<String>('join-request-notification-title'),
        "${user.data.name} ${config.get<String>('join-request-notification-body')} ${activity.title}",
        config.get<String>('join-request-notification-type'),
        user.data.uid!,
      );
    } else {
      debugPrint("Couldn't find activityCreator to send request notification to.");
    }
  }

  void sendAcceptedNotification(
      MiittiUser receiver, MiittiActivity activity) async {
    sendNotification(
      receiver.fcmToken,
      "Tervetuloa miittiin!",
      "Sut hyväksyttiin miittiin: ${activity.title}",
      "accept",
      activity.id,
    );
  }

  Future sendNotification(String receiverToken, String title, String message,
      String type, String data) async {
    debugPrint("Trying to send message: $message");
    final callable =
        FirebaseFunctions.instanceFor(region: 'europe-west1').httpsCallable('sendNotificationTo');
    try {
      final response = await callable.call({
        "receiver": receiverToken,
        "title": title,
        "message": message,
        "type": type,
        "myData": data,
      });
      debugPrint("Result sending notification: ${response.data}");
    } on FirebaseFunctionsException catch (e, s) {
      debugPrint("Error calling ${callable.toString()}: $e");
      debugPrint("$s");
    } catch (e) {
      debugPrint("Unexpected error: $e");
    }
  }

  void sendMessageNotification(String receiverToken, String senderName,
      MiittiActivity activity, String message) async {
    sendNotification(
      receiverToken,
      "Uusi viesti miitissä ${activity.title}",
      "$senderName: $message",
      "message",
      activity.id,
    );
  }
}
