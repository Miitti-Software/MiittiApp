import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:miitti_app/services/service_providers.dart';
import 'package:miitti_app/services/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A class for interfacing with the Firebase Authentication service
class AuthService {
  final FirebaseAuth _auth;
  final Ref ref;

  AuthService(this.ref) : _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  String get uid => _auth.currentUser!.uid;
  String get email => _auth.currentUser?.email ?? "";

  bool get isSignedIn => _auth.currentUser != null;
  bool isLoading = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<bool> signInWithApple() async {
    try {
      final appleProvider = AppleAuthProvider();
      await FirebaseAuth.instance.signInWithProvider(appleProvider);
      return true;
    } catch (error) {
      debugPrint('Got error signing with Apple $error');
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
      try {
        final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

        if (gUser == null) return false;

        final GoogleSignInAuthentication gAuth = await gUser.authentication;

        // Create new credentials for user
        final credential = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken,
          idToken: gAuth.idToken,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
        return true;

      } catch (error) {
        debugPrint('Got error signing with Google $error');
        return false;
      }
    }

  void afterSigning(BuildContext context) async {
    try {
      FirestoreService db = ref.read(firestoreService);
      await db.checkExistingUser(uid).then((value) async {
        if (value == true) {
          //TODO: Before publishing refactoring, delete all anonymous docs from firestore,
          //because this will incorrectly set anonymous mode off for them, and we don't use docs for anonymous users anymore
          afterFrame(() => context.go('/'));
        } else {
          afterFrame(
              () => context.go('/login/explore'));
        }
      });
    } catch (error) {
      showSnackBar(context, "Kirjautumisen käsittelyssä sattui virhe: $error!",
          AppStyle.red);
      debugPrint('Got error after signing $error');
    }
  }

  Future signOut() async {
    SharedPreferences s = await SharedPreferences.getInstance();
    ref.read(firestoreService).reset();
    await _auth.signOut();
    GoogleSignIn().signOut();
    s.clear();
  }

  Future deleteUser() {
    return _wait(() async {
      // TODO: Delete all user's profile picture variants from storage
      SharedPreferences s = await SharedPreferences.getInstance();
      await signInWithGoogle();
      ref.read(firestoreService).deleteUser();
      ref.read(firestoreService).reset();
      await _auth.currentUser!.delete();
      GoogleSignIn().signOut();
      s.clear();
    });
  }

  // Other auth-related methods
  Future<T> _wait<T>(Function action) async {
    isLoading = true;
    T result = await action();
    isLoading = false;
    return result;
  }
}
