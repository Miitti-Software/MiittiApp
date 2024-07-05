import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/screens/login/explore_decision_screen.dart';
import 'package:miitti_app/services/providers.dart';
import 'package:miitti_app/screens/index_page.dart';
import 'package:miitti_app/screens/login/login_intro.dart';
import 'package:miitti_app/functions/notification_message.dart';
import 'package:miitti_app/services/push_notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // Ensure that the WidgetsBinding has been set up before the app is run so that the widgets can interact with the Flutter engine.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the default options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase Messaging via PushNotificationService
  FirebaseMessaging.onBackgroundMessage(
      PushNotificationService.firebaseBackgroundMessage
  );
  PushNotificationService.listenForeground();
  PushNotificationService.listenTerminated();

  // Force the app to always run in portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) {
    // Run the app wrapped in a ProviderScope, which enables Riverpod state management
    runApp(const ProviderScope(child: MiittiApp()));
  });
}

class MiittiApp extends ConsumerStatefulWidget {
  const MiittiApp({super.key});

  @override
  ConsumerState<MiittiApp> createState() => _MiittiAppState();
}

class _MiittiAppState extends ConsumerState<MiittiApp> {
  @override
  Widget build(BuildContext context) {
    //ScreenUtilInit is used to make the app responsive
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, child) => MaterialApp(
        navigatorKey: navigatorKey,
        theme: miittiTheme,
        debugShowCheckedModeBanner: false,
        home: _buildAuthScreen(context),
        routes: {
          '/notificationmessage': (context) => const NotificationMessage()
        },
      ),
    );
  }

  Widget _buildAuthScreen(BuildContext context) {
    //Just checking if the user is signed up, before opening our app.
    return Consumer(builder: (context, ref, kid) {
      if (ref.read(authService).isSignedIn) {
        return FutureBuilder(
            future: ref
                .read(firestoreService)
                .checkExistingUser(ref.read(authService).uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppStyle.pink),
                    ),
                  ),
                );
              } else if (snapshot.hasError) {
                debugPrint('Error occurred: ${snapshot.error}');
                return const Scaffold(
                  body: Center(
                    child: Text('Error occurred'),
                  ),
                );
              } else if (snapshot.data == true) {
                return const IndexPage();
              } else {
                return const ExploreDecisionScreen();
              }
            });
      } else {
        return const LoginIntro();
      }
    });
  }
}
