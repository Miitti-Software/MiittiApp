import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/services/auth_service.dart';
import 'package:miitti_app/services/firestore_service.dart';
import 'package:miitti_app/services/local_storage_service.dart';
import 'package:miitti_app/services/push_notification_service.dart';
import 'package:miitti_app/services/remote_config_service.dart';
import 'package:miitti_app/services/session.dart';

// Providers are initialized upon first access

//Bool isAnonymous from fireStoreService.miittiUser == null
final isAnonymous = Provider<bool>((ref) {
  final db = ref.watch(firestoreService);
  return db.isAnonymous;
});

final providerLoading = Provider<bool>((ref) {
  final db = ref.watch(firestoreService);
  final auth = ref.watch(authService);

  return db.isLoading || auth.isLoading;
});

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
