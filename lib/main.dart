import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
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
  //Making sure that 3rd party widgets work properly
  WidgetsFlutterBinding.ensureInitialized();

  //Sets up Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  //listen to background
  FirebaseMessaging.onBackgroundMessage(
      PushNotificationService.firebaseBackgroundMessage);

  //listen to foreground
  PushNotificationService.listenForeground();

  //Listen terminated
  PushNotificationService.listenTerminated();

  //Forces the app to only work in Portarait Mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) {
    //Running the app
    //ProviderScope is used for the Riverpod state management
    runApp(const ProviderScope(child: MyApp()));
  });
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
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
      final auth = ref.read(authService);
      if (auth.isSignedIn) {
        return const IndexPage();
      } else {
        return const LoginIntro();
      }
    });
  }
}
