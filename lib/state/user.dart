import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/services/firestore_service.dart';
import 'package:miitti_app/services/local_storage_service.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/services/auth_service.dart';

class UserState extends StateNotifier<User?> {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  final LocalStorageService _localStorageService;

  UserState(this._authService, this._firestoreService, this._localStorageService) : super(null); // Initialize state to null

  User? get user => state;
  String get uid => state?.uid ?? "";
  String get email => state?.email ?? "";
  bool get isSignedIn => state != null;

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  Future<bool> signIn(apple) async {
    final result = apple ? await _authService.signInWithApple() : await _authService.signInWithGoogle();
    if (result) {
      state = await _authService.authStateChanges.first;
    }
    return result;
  }

  Future<void> signOut() async {
    state = null;
    final prefs = _localStorageService;
    _firestoreService.reset();
    await _authService.signOut();
    await prefs.clear();
    
  }

  Future<void> deleteUser() async {
    state = null;
    // TODO: Delete all user's profile picture variants from storage - whole folder corresponding to uid
    final prefs = _localStorageService;
    await _authService.deleteUser();
    await _firestoreService.deleteUser();
    _firestoreService.reset();
    await prefs.clear();
    
  }
}

final userStateProvider = StateNotifierProvider<UserState, User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  final localStorageService = ref.watch(localStorageServiceProvider);
  return UserState(authService, firestoreService, localStorageService);
});




class UserData extends StateNotifier<MiittiUser> {
  UserData(super.state);
  
}