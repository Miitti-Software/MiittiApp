import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/services/auth_service.dart';
import 'package:miitti_app/services/firestore_service.dart';
import 'package:miitti_app/services/local_storage_service.dart';
import 'package:miitti_app/services/push_notification_service.dart';
import 'package:miitti_app/services/remote_config_service.dart';
import 'package:miitti_app/services/session.dart';


// Providers exposing the service interfaces

final session = Provider<Session>((ref) {
  return Session(ref);
});

// Provider for AuthService
final authService = Provider<AuthService>((ref) {
  return AuthService(ref);
});

// Initialize Firebase Remote Config service for reading dynamic configuration values for the app from Firebase
final remoteConfigService = Provider<RemoteConfigService>((ref) {
  final service = RemoteConfigService(ref);
  service.initialize();
  return service;
});

// Provider for FirestoreService
final firestoreService = Provider<FirestoreService>((ref) {
  return FirestoreService(ref);
});

// Provider for LocalStorageService
final localStorageService = Provider<LocalStorageService>((ref) {
  return LocalStorageService(ref);
});

final notificationService = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref);
});


// Individual providers for more specialized use cases

final authState = StreamProvider<User?>((ref) {
  final authServiceInstance = ref.watch(authService);
  return authServiceInstance.authStateChanges;
});

final providerLoading = Provider<bool>((ref) {
  final db = ref.watch(firestoreService);
  final auth = ref.watch(authService);

  return db.isLoading || auth.isLoading;
});