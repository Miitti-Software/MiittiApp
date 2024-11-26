import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:miitti_app/constants/languages.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/state/map_state.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/services/push_notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:miitti_app/envs/firebase_prod_configuration.dart' as prod;
import 'package:miitti_app/envs/firebase_stag_configuration.dart' as stg;
import 'package:miitti_app/envs/firebase_dev_configuration.dart' as dev;
import 'package:miitti_app/state/settings.dart';
import 'package:miitti_app/state/user.dart';

const appVersion = '2.0.2'; // App version number - TODO: Update this here as well as in pubspec.yaml for each new release

final rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // Ensure that the WidgetsBinding has been set up before the app is run so that the widgets can interact with the Flutter engine.
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase default options for each environment
  final firebaseProd = prod.DefaultFirebaseOptions.currentPlatform;
  final firebaseStg = stg.DefaultFirebaseOptions.currentPlatform;
  final firebaseDev = dev.DefaultFirebaseOptions.currentPlatform;

  // Variable to hold the FirebaseOptions of the current environment
  late FirebaseOptions config;

  // Get the current environment name using the FLUTTER_APP_FLAVOR environment variable
  // that corresponds to the --flavor argument in the launch configuration
  const env = String.fromEnvironment('FLUTTER_APP_FLAVOR');

  // Set the Firebase configuration based on the current environment
  switch (env) {
    case "staging":
      config = firebaseStg;
      break;
    case "production":
      config = firebaseProd;
      break;
    case "development":
      config = firebaseDev;
      break;
    default:
      config = firebaseProd;
      break;
  }

  // Enable Firebase Emulators for development environment
  // if (env == "development") {
  //   try {
  //     await FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
  //     FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080);
  //     await FirebaseStorage.instance.useStorageEmulator('10.0.2.2', 9199);
  //     FirebaseFunctions.instance.useFunctionsEmulator('10.0.2.2', 5001);
  //   } catch (e) {
  //     debugPrint('Make sure the emulators are running by running `firebase emulators:start` \n Error connecting to Firebase emulators: $e');
  //   }
  // }

  // Initialize Firebase with the default options corresponding to the current environment
  await Firebase.initializeApp(
    options: config,
  );

  final container = ProviderContainer();

  await container.read(appRouterProvider).router;

 // Initialize the RemoteConfigService to fetch and activate the remote config values
  await container.read(remoteConfigServiceProvider).initialize();

  // Initialize UserState and other services
  await container.read(userStateProvider.notifier).initializeState().then((value) async {
    container.read(mapStateProvider.notifier).initializeUserData();

    // Ensure UserState is initialized before initializing PushNotificationService
    if (container.read(userStateProvider).user != null) {
      await container.read(notificationServiceProvider).initialize();
    } else {
      debugPrint('UserState is not initialized.');
    }
  });

  // Initialize Firebase Messaging via PushNotificationService
  FirebaseMessaging.onBackgroundMessage(PushNotificationService.firebaseBackgroundMessage);
  // container.read(notificationServiceProvider).listenForeground();
  container.read(notificationServiceProvider).listenTerminated();

  // Activate Firebase App Check for the current environment
  await FirebaseAppCheck.instance.activate(
    androidProvider: env == 'production' && !kDebugMode
        ? AndroidProvider.playIntegrity
        : AndroidProvider.debug,
    appleProvider:
        env == 'production' && !kDebugMode
        ? AppleProvider.deviceCheck 
        : AppleProvider.debug,
  );

  // Force the app to always run in portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) {
    // Run the app wrapped in a ProviderScope, which enables global Riverpod state management
    runApp(
      const ProviderScope(
        child: MiittiApp(),
      ),
    );
  });
}

// The main app widget at the root of the widget tree
class MiittiApp extends ConsumerWidget {
  const MiittiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider).router;
    ref.read(sessionProvider);

    // Listen to the authState changes and refresh the router when the user signs in or out to trigger a redirect automatically
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      if (previous?.value != null) {
        router.refresh();
      }
    });

    // Listen to the remoteConfig changes and refresh the router when the remote config values change to update the UI
    ref.listen<AsyncValue<Map<String, dynamic>>>(remoteConfigStreamProvider, (previous, next) {
      if (previous?.value != null) {
        router.refresh();
      }
    });

    return OverlaySupport.global(
      child: MaterialApp.router(
        routerConfig: router,
        locale: Locale(ref.watch(languageProvider).code),
        supportedLocales: Language.values.map((language) => Locale(language.code)).toList(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        title: 'Miitti',
        theme: miittiTheme,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
