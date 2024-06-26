import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/constants/app_texts.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:miitti_app/services/providers.dart';
import 'package:miitti_app/screens/index_page.dart';
import 'package:miitti_app/screens/login/explore_decision_screen.dart';
import 'package:miitti_app/screens/login/phone/phone_sms.dart';
import 'package:miitti_app/services/firestore_service.dart';
import 'package:miitti_app/widgets/other_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth;
  final Ref ref;

  AuthService(this.ref) : _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  String get uid => _auth.currentUser!.uid;
  bool get isSignedIn => _auth.currentUser != null;

  bool isLoading = false;

  Future<void> signInWithApple(BuildContext context) async {
    _wait(() async {
      try {
        showLoadingDialog(context);

        final appleProvider = AppleAuthProvider();
        await FirebaseAuth.instance.signInWithProvider(appleProvider);

        afterFrame(() => _afterSigning(context));
      } catch (error) {
        debugPrint('Got error signing with Apple $error');
        afterFrame(() {
          showSnackBar(context, "${t('login-error')}: $error!", AppStyle.red);
          Navigator.of(context).pop();
        });
      }
    });
  }

  Future signInWithGoogle(BuildContext context) async {
    _wait(() async {
      try {
        //begin interactive sign process
        final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

        //if user cancels the sign-in attempt
        if (gUser == null) return;

        //obtain auth details for request
        final GoogleSignInAuthentication gAuth = await gUser.authentication;

        //create new credentials for user
        final credential = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken,
          idToken: gAuth.idToken,
        );

        //finally, lets sign in
        if (context.mounted) {
          showLoadingDialog(context);
        }

        await FirebaseAuth.instance.signInWithCredential(credential);

        afterFrame(() => _afterSigning(context));
      } catch (error) {
        debugPrint('Got error signing with Google $error');
        afterFrame(() => showSnackBar(
            context, "${t('login-error')}: $error!", AppStyle.red));
      }
    });
  }

  Future<void> signInWithPhone(BuildContext context, String phoneNumber) async {
    _wait(() async {
      try {
        showLoadingDialog(context);
        await _auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted:
              (PhoneAuthCredential phoneAuthCredential) async {
            await _auth.signInWithCredential(phoneAuthCredential);

            afterFrame(() {
              showSnackBar(context, t('code-retrieved-automatically'),
                  Colors.green.shade600);
              _afterSigning(context);
              Navigator.of(context).pop();
            });

            debugPrint("$phoneNumber signed in");
          },
          verificationFailed: (error) {
            Navigator.of(context).pop();
            showSnackBar(
                context, "Failed phone verification: $error", AppStyle.red);

            throw Exception(error.message);
          },
          codeSent: (verificationId, forceResendingToken) {
            debugPrint("sending code to $phoneNumber");
            pushNRemoveUntil(context, PhoneSms(verificationId: verificationId));
          },
          codeAutoRetrievalTimeout: (verificationId) {},
        );
      } on FirebaseAuthException catch (e) {
        debugPrint("Kirjautuminen epäonnistui: ${e.message}");
        afterFrame(() => showSnackBar(
            context, "${t('login-error')}: ${e.message}", Colors.red.shade800));
      }
    });
  }

  void verifyOtp({
    required BuildContext context,
    required String verificationId,
    required String userOtp,
  }) async {
    _wait(() async {
      showLoadingDialog(context);
      try {
        if (_auth.currentUser == null) {
          PhoneAuthCredential creds = PhoneAuthProvider.credential(
            verificationId: verificationId,
            smsCode: userOtp,
          );

          await _auth.signInWithCredential(creds);
        }

        afterFrame(() {
          _afterSigning(context);
          Navigator.of(context).pop();
        });
      } on FirebaseAuthException catch (e) {
        debugPrint("Vahvistus epäonnistui: ${e.message} (${e.code})");
        afterFrame(() {
          showSnackBar(context, 'SMS vahvistus epäonnistui ${e.message}',
              Colors.red.shade800);
          Navigator.of(context).pop();
        });
      }
    });
  }

  void _afterSigning(BuildContext context) async {
    try {
      FirestoreService db = ref.read(firestoreService);
      db.checkExistingUser(uid).then((value) async {
        if (value == true) {
          //TODO: Before publishing refactoring, delete all anonymous docs from firestore,
          //because this will incorrectly set anonymous mode off for them, and we don't use docs for anonymous users anymore
          afterFrame(() => pushNRemoveUntil(context, const IndexPage()));
        } else {
          afterFrame(
              () => pushNRemoveUntil(context, const ExploreDecisionScreen()));
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
    s.clear();
  }

  F

  // Other auth-related methods
  Future<T> _wait<T>(Function action) async {
    isLoading = true;
    T result = await action();
    isLoading = false;
    return result;
  }
}
