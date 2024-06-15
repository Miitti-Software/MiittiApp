import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  final FirebaseAuth _auth;
  final Ref ref;

  AuthService(this.ref) : _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  String get uid => _auth.currentUser!.uid;
  bool get isSignedIn => _auth.currentUser != null;

  Future<User?> signIn(String email, String password) async {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return userCredential.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  void signInWithApple(BuildContext context) {}

  void signInWithGoogle(BuildContext context) {}

  // Other auth-related methods
}
