import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A class for interfacing with the Firebase Authentication service

//TODO: Before publishing refactoring, delete all anonymous docs from firestore,
    //because this will incorrectly set anonymous mode off for them, and we don't use docs for anonymous users anymore
class AuthService {
  final FirebaseAuth _auth;
  final Ref ref;

  AuthService(this.ref) : _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  String get uid => _auth.currentUser!.uid;
  String get email => _auth.currentUser?.email ?? "";

  bool get isSignedIn => _auth.currentUser != null;
  bool isLoading = false; // TODO: refactor out in favor of future builders and the like

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<bool> signInWithApple() async {
    try {
      final appleProvider = AppleAuthProvider();
      await FirebaseAuth.instance.signInWithProvider(appleProvider);
      return true;
    } catch (error) {
      debugPrint('Error signing in with Apple: $error');
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
      if (gUser == null) return false;

      final GoogleSignInAuthentication gAuth = await gUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      return true;
    } catch (error) {
      debugPrint('Error signing in with Google: $error');
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

  Future<void> deleteUser() async {
    // TODO: Delete all user's profile picture variants from storage - whole folder corresponding to uid
    return _performActionWithLoading(() async {
      await signInWithGoogle();
      await _auth.currentUser!.delete();
      await GoogleSignIn().signOut();
    });
  }

  Future<T> _performActionWithLoading<T>(Future<T> Function() action) async {
    isLoading = true;
    try {
      return await action();
    } finally {
      isLoading = false;
    }
  }
}
