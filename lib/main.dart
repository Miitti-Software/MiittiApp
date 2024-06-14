import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/providers.dart';
import 'package:miitti_app/screens/index_page.dart';
import 'package:miitti_app/screens/login/login_intro.dart';
import 'package:miitti_app/functions/notification_message.dart';
import 'package:miitti_app/functions/push_notifications.dart';
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
      PushNotifications.firebaseBackgroundMessage);

  //listen to foreground
  PushNotifications.listenForeground();

  //Listen terminated
  PushNotifications.listenTerminated();

  //Forces the app to only work in Portarait Mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) {
    //Running the app
    runApp(const MyApp());
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    //ProviderScope is used for the Riverpod state management
    return ProviderScope(child: Builder(
      builder: (context) {
        //ScreenUtilInit is used to make the app responsive
        return ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => MaterialApp(
            navigatorKey: navigatorKey,
            theme: ThemeData(
              scaffoldBackgroundColor: AppStyle.black,
              fontFamily: 'RedHatDisplay',
            ),
            debugShowCheckedModeBanner: false,
            home: _buildAuthScreen(context),
            routes: {
              '/notificationmessage': (context) => const NotificationMessage()
            },
          ),
        );
      },
    ));
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
