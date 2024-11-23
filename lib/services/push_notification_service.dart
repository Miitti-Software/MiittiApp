import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/models/user_created_activity.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/main.dart';
import 'package:miitti_app/services/firestore_service.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:miitti_app/state/user.dart';
import 'dart:convert';

import 'package:permission_handler/permission_handler.dart';

final pushNotificationServiceProvider = StateNotifierProvider<PushNotificationService, bool>((ref) {
  return PushNotificationService(ref);
});

class PushNotificationService extends StateNotifier<bool> {
  final Ref ref;
  static BuildContext get context => rootNavigatorKey.currentContext!;
  final _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  PushNotificationService(this.ref) : super(false) {
    initialize();
  }

  bool get isNotificationsEnabled => state;

  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      if (enabled) {
        final permissionGranted = await requestPermission(true);
        if (permissionGranted) {
          await _requestAndSetupNotifications();
          await _saveNotificationState(true);
        } else {
          state = false; // Update state if permission denied
          await _saveNotificationState(false);
        }
      } else {
        state = false;
        await _firebaseMessaging.deleteToken();
        await _saveNotificationState(false);
      }
    } catch (e) {
      debugPrint('Error toggling notifications: $e');
      state = await Permission.notification.isGranted; // Revert to actual state
      await _saveNotificationState(state);
    }
  }

  Future<bool> checkPermission() async {
    final permission = await Permission.notification.isGranted;
    state = permission;
    return permission;
  }

  Future<void> initialize() async {
    // Load saved notification state
    final savedState = await ref.read(localStorageServiceProvider).getBool('notifications_enabled') ?? false;
    state = savedState;

    // Handle background notification taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.notification != null) {
        debugPrint("Background notification tapped");
        _handleNotificationTap(message);
      }
    });

    if (state) {
      await _requestAndSetupNotifications();
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    try {
      final String? route = message.data['route'];
      if (route != null) {
        debugPrint("Notification tapped: $route");
        if (route.contains("/activity/")) {
          final activityId = route.split("/")[2];
          Future.delayed(const Duration(milliseconds: 2), () {
            context.go('/activity/$activityId');
            Future.delayed(const Duration(milliseconds: 200), () {
              context.go(route);
            });
          });
        } else {
          context.go(route);
        }
      } else {
        debugPrint("No route found in notification data");
        context.go('/');
      }
    } catch (e) {
      debugPrint("Error handling notification tap: $e");
    }
  }

  Future<void> _requestAndSetupNotifications() async {
    final result = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      provisional: true,
      sound: true
    );

    state = result.authorizationStatus == AuthorizationStatus.authorized ||
            result.authorizationStatus == AuthorizationStatus.provisional;

    if (state) {
      await _setupNotifications();
    }
  }

  Future<void> _setupNotifications() async {
    if (Platform.isIOS) {
      await _firebaseMessaging.getAPNSToken();
      await Future.delayed(const Duration(seconds: 1));
    }

    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      debugPrint("FCM Token: $token");
      
      // Update user's FCM token if changed
      final userState = ref.read(userStateProvider);
      if (userState.data.fcmToken != token) {
        ref.read(userStateProvider.notifier).update(
          (state) => state.copyWith(data: state.data.setFcmToken(token))
        );
        await ref.read(userStateProvider.notifier).updateUserData();
      }
    }

    listenForeground();
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

  // Initialize local notifications
  Future localNotiInit() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_stat_name');
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin);
    _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onNotificationTap,
        onDidReceiveBackgroundNotificationResponse: onNotificationTap);
  }

  void listenForeground() {
    // Handle foreground notifications
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

  void listenTerminated() async {
    // Handle notifications in terminated state
    final RemoteMessage? message =
        await FirebaseMessaging.instance.getInitialMessage();

    if (message != null) {
      debugPrint("Launched from terminated state");
      Future.delayed(const Duration(seconds: 2), () {
        _handleNotificationTap(message);
      });
    }
  }

  static void onNotificationTap(NotificationResponse notificationResponse) async {
    if (notificationResponse.payload != null) {
      final Map<String, dynamic> payloadData = jsonDecode(notificationResponse.payload!);
      final String route = payloadData['route'];
      context.go(route);
    }
  }

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

  Future<void> _saveNotificationState(bool enabled) async {
    await ref.read(localStorageServiceProvider).saveBool('notifications_enabled', enabled);
  }

  void sendInviteNotification(MiittiUser current, MiittiUser receiver, UserCreatedActivity activity) async {
    final config = ref.read(remoteConfigServiceProvider);
    final language = receiver.languageSetting;
    sendNotification(
      receiver.fcmToken,
      config.getNotificationTemplateString('invite-notification-title', language),
      "${current.name} ${config.getNotificationTemplateString('invite-notification-body', language)} ${activity.title}",
      config.getNotificationTemplateString('invite-notification-type', language),
      '/activity/${activity.id}',
    );
  }

  Future sendRequestNotification(UserCreatedActivity activity) async {
    FirestoreService firestore = ref.read(firestoreServiceProvider);
    final config = ref.read(remoteConfigServiceProvider);
    UserStateData user = ref.read(userStateProvider);
    MiittiUser? creator = await firestore.fetchUser(activity.creator);
    if (creator != null) {
      final language = creator.languageSetting;
      sendNotification(
        creator.fcmToken,
        config.getNotificationTemplateString('join-request-notification-title', language),
        "${user.data.name} ${config.getNotificationTemplateString('join-request-notification-body', language)} ${activity.title}",
        config.getNotificationTemplateString('join-request-notification-type', language),
        '/activity/${activity.id}/requests',
      );
    } else {
      debugPrint("Couldn't find creator to send request notification to.");
    }
  }

  Future sendRequestAcceptedNotification(UserCreatedActivity activity) async {
    FirestoreService firestore = ref.read(firestoreServiceProvider);
    final config = ref.read(remoteConfigServiceProvider);
    UserStateData user = ref.read(userStateProvider);
    MiittiUser? requestor = await firestore.fetchUser(user.data.uid!);
    if (requestor != null) {
      final language = requestor.languageSetting;
      sendNotification(
        requestor.fcmToken,
        config.getNotificationTemplateString('join-request-accepted-notification-title', language),
        "${activity.title} ${config.getNotificationTemplateString('join-request-accepted-notification-body', language)}",
        config.getNotificationTemplateString('join-request-accepted-notification-type', language),
        '/activity/${activity.id}',
      );
    } else {
      debugPrint("Couldn't find requestor to send request notification to.");
    }
  }

  Future sendJoinNotification(UserCreatedActivity activity) async {
    FirestoreService firestore = ref.read(firestoreServiceProvider);
    final config = ref.read(remoteConfigServiceProvider);
    UserStateData user = ref.read(userStateProvider);
    MiittiUser? activityCreator = await firestore.fetchUser(activity.creator);
    if (activityCreator != null) {
      final language = activityCreator.languageSetting;
      sendNotification(
        activityCreator.fcmToken,
        config.getNotificationTemplateString('join-notification-title', language),
        "${user.data.name} ${config.getNotificationTemplateString('join-notification-body', language)} ${activity.title}",
        config.getNotificationTemplateString('join-notification-type', language),
        '/activity/${activity.id}',
      );
    } else {
      debugPrint("Couldn't find activityCreator to send request notification to.");
    }
  }

  Future sendCancelNotification(UserCreatedActivity activity) async {
    FirestoreService firestore = ref.read(firestoreServiceProvider);
    final config = ref.read(remoteConfigServiceProvider);
    UserStateData user = ref.read(userStateProvider);
    MiittiUser? activityCreator = await firestore.fetchUser(activity.creator);
    if (activityCreator != null) {
      final language = activityCreator.languageSetting;
      sendNotification(
        activityCreator.fcmToken,
        config.getNotificationTemplateString('cancel-notification-title', language),
        "${user.data.name} ${config.getNotificationTemplateString('cancel-notification-body', language)} ${activity.title}",
        config.getNotificationTemplateString('cancel-notification-type', language),
        '/activity/${activity.id}',
      );
    } else {
      debugPrint("Couldn't find activityCreator to send request notification to.");
    }
  }

  Future sendMessageNotification(String receiverToken, String message, MiittiActivity activity, String senderName) async {
    final config = ref.read(remoteConfigServiceProvider);
    final language = ref.read(userStateProvider).data.languageSetting;
    sendNotification(
      receiverToken,
      activity.title,
      "$senderName: $message",
      config.getNotificationTemplateString('message-notification-type', language),
      '/activity/${activity.id}/chat',
    );
  }

  void sendAcceptedNotification(
      MiittiUser receiver, MiittiActivity activity) async {
    sendNotification(
      receiver.fcmToken,
      "Tervetuloa miittiin!",
      "Sut hyväksyttiin miittiin: ${activity.title}",
      "accept",
      '/activity/${activity.id}',
    );
  }

  Future sendNotification(String receiverToken, String title, String message,
      String type, String route) async {
    debugPrint("Trying to send message: $message");
    final callable =
        FirebaseFunctions.instanceFor(region: 'europe-west1').httpsCallable('sendNotificationTo');
    try {
      final response = await callable.call({
        "receiver": receiverToken,
        "title": title,
        "message": message,
        "type": type,
        "route": route,
      });
      debugPrint("Result sending notification: ${response.data}");
    } on FirebaseFunctionsException catch (e, s) {
      debugPrint("Error calling ${callable.toString()}: $e");
      debugPrint("$s");
    } catch (e) {
      debugPrint("Unexpected error: $e");
    }
  }
}
