import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/constants/languages.dart';
import 'package:miitti_app/main.dart';
import 'package:miitti_app/routing/app_router.dart';
import 'package:miitti_app/services/auth_service.dart';
import 'package:miitti_app/services/firebase_storage_service.dart';
import 'package:miitti_app/services/firestore_service.dart';
import 'package:miitti_app/services/local_storage_service.dart';
import 'package:miitti_app/services/push_notification_service.dart';
import 'package:miitti_app/services/remote_config_service.dart';
import 'package:miitti_app/services/session.dart';
import 'package:miitti_app/state/settings.dart';

// Providers exposing the service interfaces

final sessionProvider = Provider<Session>((ref) {
  return Session(ref);
});

// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref);
});

final appRouterProvider = Provider<AppRouter>((ref) {
  return AppRouter(ref, rootNavigatorKey);
});

// Initialize Firebase Remote Config service for reading dynamic configuration values for the app from Firebase
final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  final service = RemoteConfigService(ref);
  service.initialize();
  ref.listen<Language?>(languageProvider, (_, currentLanguage) async {
    await service.fetchAndActivate(currentLanguage);
  });
  return service;
});

// Provider for FirestoreService
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(ref);
});

// Provider for FirebaseStorageService
final firebaseStorageServiceProvider = Provider<FirebaseStorageService>((ref) {
  return FirebaseStorageService(ref);
});

// Provider for LocalStorageService
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService(ref);
});

final notificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref);
});

// Individual providers for more specialized use cases

// Provider for RemoteConfigService stream
final remoteConfigStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final remoteConfigServiceInstance = ref.watch(remoteConfigServiceProvider);
  return remoteConfigServiceInstance.configStream;
});