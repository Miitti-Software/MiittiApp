import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/services/auth_service.dart';
import 'package:miitti_app/services/firestore_service.dart';
import 'package:miitti_app/services/local_storage_service.dart';

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
