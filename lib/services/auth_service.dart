import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// A class for interfacing with the Firebase Authentication service

//TODO: Before publishing refactoring, delete all anonymous docs from firestore,
    //because this will incorrectly set anonymous mode off for them, and we don't use docs for anonymous users anymore
class AuthService {
  final FirebaseAuth _auth;
  final Ref ref;

  AuthService(this.ref) : _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
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
    try {
      List<UserInfo> providerData = _auth.currentUser!.providerData;
      
      for (var provider in providerData) {
        if (provider.providerId == 'google.com') {
          await signInWithGoogle();
          await _auth.currentUser!.delete();
          await GoogleSignIn().signOut();
        } else if (provider.providerId == 'apple.com') {
          await signInWithApple();
          await _auth.currentUser!.delete();
        }
      }
    } catch (error) {
      debugPrint('Error deleting user: $error');
    }
  }
}
