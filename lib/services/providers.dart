import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/services/auth_service.dart';
import 'package:miitti_app/services/firestore_service.dart';
import 'package:miitti_app/services/local_storage_service.dart';
import 'package:miitti_app/services/push_notification_service.dart';

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

// Provider for AuthService
final authService = Provider<AuthService>((ref) {
  return AuthService(ref);
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
