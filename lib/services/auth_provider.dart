// ignore_for_file: use_build_context_synchronously

// #region depedencies
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:miitti_app/screens/chat_page.dart';
import 'package:miitti_app/screens/commercialScreens/comact_detailspage.dart';
import 'package:miitti_app/screens/commercialScreens/comchat_page.dart';
import 'package:miitti_app/models/ad_banner.dart';
import 'package:miitti_app/models/commercial_activity.dart';
import 'package:miitti_app/models/commercial_spot.dart';
import 'package:miitti_app/models/commercial_user.dart';
import 'package:miitti_app/constants/constants.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/widgets/other_widgets.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/models/person_activity.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/models/report.dart';
import 'package:miitti_app/screens/activity_details_page.dart';
import 'package:miitti_app/functions/filter_settings.dart';
import 'package:miitti_app/screens/index_page.dart';

import 'package:miitti_app/screens/login/login_decide_screen.dart';
import 'package:miitti_app/screens/login/phone/phone_sms.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
// #endregion

class AuthProvider extends ChangeNotifier {
// #region Variables

  static const String _usersString = "users";
  static const String _activitiesString = "activities";
  static const String _comactString = "commercialActivities";

  bool _isSignedIn = false;
  bool get isSignedIn => _isSignedIn;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isAnonymous = true;
  bool get isAnonymous => _isAnonymous;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;

  String? _uid;
  String get uid => _uid!;
  bool get userNull => _uid == null;

  MiittiUser? _miittiUser;
  MiittiUser get miittiUser => _miittiUser!;

  PersonActivity? _miittiActivity;
  PersonActivity get miittiActivity => _miittiActivity!;

  AuthProvider(BuildContext context) {
    checkSign(context);
  }

// #endregion

// #region SignIn
  Future<bool> checkSign(BuildContext context) async {
    final SharedPreferences s = await SharedPreferences.getInstance();
    _isSignedIn = s.getBool('is_signedin') ?? false;
    if (_isSignedIn) {
      await getDataFromSp();
    }
    /* if (signedIn) {
      bool exists = await checkExistingUser();
      if (exists) {
        _isSignedIn = true;
      } else {
        showSnackBar(context, "Vaikuttaa siltä, että tilisi on poistettu",
            Colors.red.shade800);
        _isSignedIn = false;
        s.clear();
      }
    } else {
      _isSignedIn = false;
    }*/
    notifyListeners();
    return _isSignedIn;
  }

  /*Future<bool> checkAnon() async {
    final SharedPreferences s = await SharedPreferences.getInstance();
    _isAnonymous = s.getBool('is_anonymous') ?? true;

    notifyListeners();
    return _isAnonymous;
  }*/

  Future setSignIn() async {
    SharedPreferences s = await SharedPreferences.getInstance();
    await s.setBool('is_signedin', true);
    _isSignedIn = true;
    notifyListeners();
  }

  Future setAnonymousModeOn() async {
    SharedPreferences s = await SharedPreferences.getInstance();
    await s.setBool('is_anonymous', true);
    _isAnonymous = true;
    notifyListeners();
  }

  Future setAnonymousModeOff() async {
    SharedPreferences s = await SharedPreferences.getInstance();
    await s.setBool('is_anonymous', false);
    _isAnonymous = false;
    notifyListeners();
  }

  Future<void> signInWithPhone(BuildContext context, String phoneNumber) async {
    try {
      OtherWidgets.showLoadingDialog(context);
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential phoneAuthCredential) async {
          User? user =
              (await _firebaseAuth.signInWithCredential(phoneAuthCredential))
                  .user;
          _uid = user?.uid;

          showSnackBar(
              context, "Koodi saatu automaattisesti!", Colors.green.shade600);

          afterSigning(context);
          Navigator.of(context).pop();
          debugPrint("$phoneNumber signed in");
        },
        verificationFailed: (error) {
          Navigator.of(context).pop();
          showSnackBar(context, "Failed phone verification: $error",
              Colors.red.shade800);

          throw Exception(error.message);
        },
        codeSent: (verificationId, forceResendingToken) {
          debugPrint("sending code to $phoneNumber");
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => PhoneSms(
                    verificationId: verificationId,
                  ),
                ),
                (route) => route.isFirst);
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {},
      );
    } on FirebaseAuthException catch (e) {
      debugPrint("Kirjautuminen epäonnistui: ${e.message}");
      showSnackBar(context, "Kirjautuminen epäonnistui: ${e.message}",
          Colors.red.shade800);
    }
  }

  void verifyOtp({
    required BuildContext context,
    required String verificationId,
    required String userOtp,
    required Function onSuccess,
  }) async {
    OtherWidgets.showLoadingDialog(context);
    try {
      if (!(_firebaseAuth.currentUser != null &&
          _firebaseAuth.currentUser!.uid == _uid)) {
        PhoneAuthCredential creds = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: userOtp,
        );

        User? user = (await _firebaseAuth.signInWithCredential(creds)).user;
        _uid = user?.uid;
      }

      onSuccess();
    } on FirebaseAuthException catch (e) {
      debugPrint("Vahvistus epäonnistui: ${e.message} (${e.code})");
      showSnackBar(context, 'SMS vahvistus epäonnistui ${e.message}',
          Colors.red.shade800);
    } finally {
      Navigator.of(context).pop();
    }
  }

  Future signInWithGoogle(BuildContext context) async {
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
      OtherWidgets.showLoadingDialog(context);
      User? user =
          (await FirebaseAuth.instance.signInWithCredential(credential)).user;

      //assign _uid to user id
      _uid = user?.uid;

      afterSigning(context);
    } catch (error) {
      showSnackBar(context, "Kirjautuminen epäonnistui: $error!", AppStyle.red);
      debugPrint('Got error signing with Google $error');
    }
  }

  Future<void> signInWithApple(BuildContext context) async {
    try {
      OtherWidgets.showLoadingDialog(context);

      final appleProvider = AppleAuthProvider();
      User? user =
          (await FirebaseAuth.instance.signInWithProvider(appleProvider)).user;

      _uid = user?.uid;

      afterSigning(context);
    } catch (error) {
      showSnackBar(context, "Kirjautuminen epäonnistui: $error!", AppStyle.red);
      debugPrint('Got error signing with Apple $error');
      Navigator.of(context).pop();
    }
  }

  void afterSigning(BuildContext context) async {
    try {
      checkExistingUser().then((value) async {
        if (value == true) {
          //check if the user is anonymous
          checkAnonymousUser().then((value) async {
            if (value == true) {
              await setSignIn();
              await setAnonymousModeOn();
              pushNRemoveUntil(context, const IndexPage());
            } else {
              await setAnonymousModeOff();
              await getDataFromFirestore();
              await saveUserDataToSP();
              await setSignIn();
              pushNRemoveUntil(context, const IndexPage());
            }
          });
          return;
        } else {
          await setSignIn();
          await setAnonymousModeOn();
          pushNRemoveUntil(context, const LoginDecideScreen());
        }
      });
    } catch (error) {
      showSnackBar(context, "Kirjautumisen käsittelyssä sattui virhe: $error!",
          AppStyle.red);
      debugPrint('Got error after signing $error');
    }
  }

  String getUserEmail() {
    try {
      User? user = _firebaseAuth.currentUser;
      return user?.email ?? "";
    } catch (e) {
      debugPrint('Error getting user email: $e');
      return "";
    }
  }

// #endregion

// #region Report

  Future<void> reportUser(
      String message, String reportedId, String senderId) async {
    try {
      _isLoading = true;
      notifyListeners();

      DocumentSnapshot documentSnapshot =
          await _fireStore.collection('reportedUsers').doc(reportedId).get();

      Report report;
      if (documentSnapshot.exists) {
        report = Report.fromMap(
            documentSnapshot.data() as Map<String, dynamic>, true);
        report.reasons.add("$senderId: $message");
      } else {
        report = Report(
          reportedId: reportedId,
          reasons: ["$senderId: $message"],
          isUser: true,
        );
      }
      await _fireStore
          .collection('reportedUsers')
          .doc(reportedId)
          .set(report.toMap());
    } catch (e) {
      debugPrint("Reporting failed: $e");
    } finally {
      Timer(const Duration(seconds: 1), () {
        _isLoading = false;
        notifyListeners();
      });
    }
  }

  Future<void> reportActivity(
      String message, String reportedId, String senderId) async {
    try {
      _isLoading = true;
      notifyListeners();

      DocumentSnapshot documentSnapshot = await _fireStore
          .collection('reportedActivities')
          .doc(reportedId)
          .get();

      Report report;
      if (documentSnapshot.exists) {
        report = Report.fromMap(
            documentSnapshot.data() as Map<String, dynamic>, false);
        report.reasons.add("$senderId: $message");
      } else {
        report = Report(
          reportedId: reportedId,
          reasons: ["$senderId: $message"],
          isUser: false,
        );
      }
      await _fireStore
          .collection('reportedActivities')
          .doc(reportedId)
          .set(report.toMap());
    } catch (e) {
      debugPrint("Reporting failed: $e");
    } finally {
      Timer(const Duration(seconds: 1), () {
        _isLoading = false;
        notifyListeners();
      });
    }
  }

  Future<List<PersonActivity>> fetchReportedActivities() async {
    try {
      QuerySnapshot querySnapshot = await _getFireQuery('reportedActivities');

      List<PersonActivity> list = [];

      for (QueryDocumentSnapshot report in querySnapshot.docs) {
        DocumentSnapshot doc = await _getActivityDoc(report.id);
        list.add(PersonActivity.fromMap(doc.data() as Map<String, dynamic>));
      }

      return list;
    } catch (e) {
      debugPrint('Error fetching reported activities: $e');
      return [];
    }
  }

// #endregion

  // #region Ads
  Future<List<AdBanner>> fetchAds() async {
    try {
      QuerySnapshot querySnapshot = await _getFireQuery('adBanners');

      List<AdBanner> list = querySnapshot.docs
          .map((doc) => AdBanner.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      if (_miittiUser != null) {
        return AdBanner.sortBanners(list, miittiUser);
      } else {
        list.shuffle();
        return list;
      }
    } catch (e) {
      debugPrint("Error fetching ads $e");
      return [];
    }
  }

  void addAdView(String adUid) async {
    try {
      await _fireStore.collection('adBanners').doc(adUid).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error adding view: $e');
    }
  }

  void addAdClick(String adUid) async {
    try {
      await _fireStore.collection('adBanners').doc(adUid).update({
        'clicks': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error adding view: $e');
    }
  }
// #endregion

// #region Activities

  Future<void> saveMiittiActivityDataToFirebase({
    required BuildContext context,
    required PersonActivity activityModel,
  }) async {
    OtherWidgets.showLoadingDialog(context);
    try {
      activityModel.admin = _miittiUser!.uid;
      activityModel.adminAge = calculateAge(_miittiUser!.userBirthday);
      activityModel.adminGender = _miittiUser!.userGender;
      activityModel.activityUid = generateCustomId();
      activityModel.participants.add(_miittiUser!.uid);

      _miittiActivity = activityModel;

      await _activityDocRef(activityModel.activityUid)
          .set(activityModel.toMap())
          .then((value) {
        showSnackBar(context, 'Miittisi on luotu onnistuneesti!', Colors.green);

        pushNRemoveUntil(context, const IndexPage());
      });
    } on FirebaseAuthException catch (e) {
      showSnackBar(context, e.message.toString(), AppStyle.red);
      pushNRemoveUntil(context, const IndexPage());
    }
  }

  Future<List<MiittiActivity>> fetchActivities() async {
    try {
      FilterSettings filterSettings = FilterSettings();
      await filterSettings.loadPreferences();

      QuerySnapshot querySnapshot = await _getFireQuery(_activitiesString);

      List<MiittiActivity> activities = querySnapshot.docs
          .map((doc) => PersonActivity.fromDoc(doc))
          .where((activity) {
        if (daysSince(activity.activityTime) <
            (activity.timeDecidedLater ? -30 : -7)) {
          removeActivity(activity.activityUid);
          return false;
        }

        if (_miittiUser != null &&
            filterSettings.sameGender &&
            activity.adminGender != miittiUser.userGender) {
          return false;
        }
        if (!filterSettings.multiplePeople && activity.personLimit > 2) {
          return false;
        }
        if (activity.adminAge < filterSettings.minAge ||
            activity.adminAge > filterSettings.maxAge) {
          return false;
        }

        return true;
      }).toList();

      QuerySnapshot commercialQuery = await _getFireQuery(_comactString);

      List<MiittiActivity> comActivities = commercialQuery.docs
          .map((doc) => CommercialActivity.fromDoc(doc))
          .where((activity) {
        if (_miittiUser == null) {
          debugPrint("User is null");
        } else {
          debugPrint("Checking filters of ${_miittiUser?.userName}");
          if (daysSince(activity.endTime) < -1) {
            return false;
          }
        }

        return true;
      }).toList();

      List<MiittiActivity> list = List<MiittiActivity>.from(activities);
      list.addAll(List<MiittiActivity>.from(comActivities));
      return list;
    } catch (e) {
      debugPrint('Error fetching activities: $e');
      return [];
    }
  }

  Future<List<MiittiActivity>> fetchUserActivities() async {
    try {
      QuerySnapshot querySnapshot =
          await _queryWhereContains(_activitiesString, 'participants', uid);

      QuerySnapshot commercialSnapshot =
          await _queryWhereContains(_comactString, 'participants', uid);

      QuerySnapshot requestSnapshot =
          await _queryWhereContains(_activitiesString, "requests", uid);

      List<PersonActivity> personActivities = [];
      List<CommercialActivity> commercialActivities = [];

      for (var doc in querySnapshot.docs) {
        personActivities.add(PersonActivity.fromDoc(doc));
      }

      for (var doc in commercialSnapshot.docs) {
        commercialActivities.add(CommercialActivity.fromDoc(doc));
      }

      for (var doc in requestSnapshot.docs) {
        personActivities.add(PersonActivity.fromDoc(doc));
      }

      if (miittiUser.invitedActivities.isNotEmpty) {
        for (String activityId in miittiUser.invitedActivities) {
          DocumentSnapshot activitySnapshot = await _getActivityDoc(activityId);

          if (activitySnapshot.exists) {
            PersonActivity activity = PersonActivity.fromMap(
                activitySnapshot.data() as Map<String, dynamic>);
            personActivities.add(activity);
          }
        }
      }

      List<MiittiActivity> list = List<MiittiActivity>.from(personActivities);
      list.addAll(List<MiittiActivity>.from(commercialActivities));
      return list;
    } catch (e, s) {
      debugPrint('Error fetching user activities: $e, $s');
      return [];
    }
  }

  Future removeActivity(String activityId) async {
    try {
      var activityRef = _activityDocRef(activityId);

      //Delete messages subcollection
      await activityRef.collection('messages').get().then((snapshot) {
        for (DocumentSnapshot ds in snapshot.docs) {
          ds.reference.delete();
        }
      });

      await activityRef
          .delete()
          .then((value) => debugPrint("Activity Removed!"));
    } catch (e) {
      debugPrint('Error deleting activity: $e');
      return [];
    } finally {}
  }

  Future<List<PersonActivity>> fetchAdminActivities() async {
    try {
      QuerySnapshot querySnapshot =
          await _queryWhereEquals(_activitiesString, 'admin', uid);

      List<PersonActivity> activities =
          querySnapshot.docs.map((doc) => PersonActivity.fromDoc(doc)).toList();

      return activities;
    } catch (e) {
      debugPrint('Error fetching user activities: $e');
      return [];
    }
  }

  Future<int> adminActivitiesLength() async {
    try {
      QuerySnapshot querySnapshot =
          await _queryWhereEquals(_activitiesString, 'admin', uid);

      return querySnapshot.docs.length;
    } catch (e) {
      debugPrint('Error fetching user activities: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> fetchActivitiesRequests() async {
    try {
      QuerySnapshot querySnapshot =
          await _queryWhereEquals(_activitiesString, 'admin', uid);

      List<PersonActivity> activities =
          querySnapshot.docs.map((doc) => PersonActivity.fromDoc(doc)).toList();

      List<Map<String, dynamic>> usersAndActivityIds = [];

      for (PersonActivity activity in activities) {
        List<MiittiUser> users = await fetchUsersByUids(activity.requests);
        usersAndActivityIds.addAll(users.map((user) => {
              'user': user,
              'activity': activity,
            }));
      }

      return usersAndActivityIds.toList();
    } catch (e) {
      debugPrint('Error fetching admin activities: $e');
      return [];
    }
  }

  Future<List<PersonActivity>> fetchActivitiesRequestsFrom(
      String userId) async {
    try {
      QuerySnapshot querySnapshot = await _fireStore
          .collection('activities')
          .where('admin', isEqualTo: uid)
          .where('requests', arrayContains: userId)
          .get();

      List<PersonActivity> activities =
          querySnapshot.docs.map((doc) => PersonActivity.fromDoc(doc)).toList();
      return activities;
    } catch (e) {
      debugPrint('Error fetching admin activities: $e');
      return [];
    }
  }

  Future<MiittiActivity> getSingleActivity(String activityId) async {
    MiittiActivity activity;

    activity = await _personalOrCommercial(activityId, (a) {}, (comA) {});

    return activity;
  }

  Future<Widget> getDetailsPage(String activityId) async {
    try {
      Widget widget = const IndexPage();
      await _personalOrCommercial(
          activityId,
          (activity) => widget = ActivityDetailsPage(myActivity: activity),
          (comActivity) => widget = ComActDetailsPage(myActivity: comActivity));
      return widget;
    } catch (e) {
      debugPrint('Error getting details page: $e');
      return const IndexPage();
    }
  }

  Future<List<CommercialSpot>> fetchCommercialSpots() async {
    try {
      QuerySnapshot querySnapshot = await _getFireQuery('commercialSpots');

      List<CommercialSpot> spots = querySnapshot.docs
          .map((doc) =>
              CommercialSpot.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      return spots;
    } catch (e) {
      debugPrint('Error fetching commercial spots: $e');
      return [];
    }
  }

// #endregion

// #region UsersInActivities

  Future<void> sendActivityRequest(String activityId) async {
    try {
      await _activityDocRef(activityId).update({
        'requests': FieldValue.arrayUnion([_uid])
      }).then((value) {
        debugPrint("User joined the activity successfully");
      }).catchError((error) {
        debugPrint("Error joining the activity: $error");
      });
    } catch (e) {
      debugPrint('Error while joining activity: $e');
    }
  }

  Future<void> joinCommercialActivity(String activityId) async {
    try {
      await _comActivityDocRef(activityId).update({
        'participants': FieldValue.arrayUnion([_uid])
      }).then((value) {
        debugPrint("User joined the activity successfully");
      }).catchError((error) {
        debugPrint("Error joining the activity: $error");
      });
    } catch (e) {
      debugPrint('Error while joining activity: $e');
    }
  }

  Future<UserStatusInActivity> joinOrRequestActivity(String activityId) async {
    if (miittiUser.invitedActivities.contains(activityId)) {
      await reactToInvite(activityId, true);
      return UserStatusInActivity.joined;
    } else {
      await sendActivityRequest(activityId);
      return UserStatusInActivity.requested;
    }
  }

  Future<bool> reactToInvite(String activityId, bool accepted) async {
    bool operationCompleted = false;
    try {
      await _tryGetUser(uid, (user) async {
        user.invitedActivities.remove(activityId);
        await _userDocRef(uid)
            .update({'invitedActivities': user.invitedActivities.toList()});
        if (accepted) {
          await updateUserJoiningActivity(activityId, uid, true);
          operationCompleted = true;
        }
      }, () {});
    } catch (e) {
      debugPrint('Found error accepting invite: $e');
    }
    return operationCompleted;
  }

  Future inviteUserToYourActivity(
    String userId,
    String activityId,
  ) async {
    try {
      await _tryGetUser(uid, (user) async {
        user.invitedActivities.add(activityId);
        await _userDocRef(userId)
            .update({'invitedActivities': user.invitedActivities.toList()});
      }, () {});
    } catch (e) {
      debugPrint('Got this error while inviting user to your activity $e');
    }
  }

  Future<bool> checkIfUserJoined(String activityUid,
      {bool commercial = false}) async {
    final snapshot = await _fireStore
        .collection(commercial ? 'commercialActivities' : 'activities')
        .doc(activityUid)
        .get();

    if (snapshot.exists) {
      final activity = commercial
          ? CommercialActivity.fromDoc(snapshot)
          : PersonActivity.fromDoc(snapshot);
      return activity.participants.contains(uid);
    }

    return false;
  }

  Future<UserStatusInActivity> getUserStatusInActivity(
      String activityUid) async {
    try {
      final snapshot = await _getActivityDoc(activityUid);

      if (snapshot.exists) {
        final activity = PersonActivity.fromDoc(snapshot);
        if (activity.participants.contains(uid)) {
          return UserStatusInActivity.joined;
        } else if (activity.requests.contains(uid)) {
          return UserStatusInActivity.requested;
        }
      }

      return UserStatusInActivity.none;
    } catch (e) {
      debugPrint('Error getting user status in activity: $e');
      return UserStatusInActivity.none;
    }
  }

  Future<bool> checkIfUserRequested(String activityUid) async {
    final snapshot = await _getActivityDoc(activityUid);

    if (snapshot.exists) {
      final activity = PersonActivity.fromDoc(snapshot);
      return activity.requests.contains(uid);
    }

    return false;
  }

  Future<bool> updateUserJoiningActivity(
    String activityId,
    String userId,
    bool accept,
  ) async {
    bool joined = false;

    try {
      final activityRef = _fireStore.collection('activities').doc(activityId);

      await _fireStore.runTransaction((transaction) async {
        final activitySnapshot = await transaction.get(activityRef);
        if (!activitySnapshot.exists) {
          debugPrint('Activity does not exist.');
          return;
        }

        final activityData = activitySnapshot.data();
        final List<dynamic> participants = activityData?['participants'];
        final List<dynamic> requests = activityData?['requests'];

        // Remove user ID from requests
        requests.remove(userId);

        // Add user ID to participants if not already present
        if (!participants.contains(userId) && accept) {
          participants.add(userId);
          joined = true;
        }

        transaction.update(activityRef, {
          'participants': participants,
          'requests': requests,
        });
      });
    } catch (e) {
      debugPrint('Error while joining activity: $e');
    }
    return joined;
  }

  Future<void> removeUserFromActivity(
    String activityId,
    bool isRequested,
  ) async {
    try {
      if (!isRequested) {
        //check if activity or commercial activity
        DocumentReference activityRef = _activityDocRef(activityId);
        DocumentSnapshot snapshot = await activityRef.get();

        if (snapshot.exists) {
          await activityRef.update({
            'participants': FieldValue.arrayRemove([uid])
          });
        } else {
          await _comActivityDocRef(activityId).update({
            'participants': FieldValue.arrayRemove([uid])
          });
        }
      } else {
        await _activityDocRef(activityId).update({
          'requests': FieldValue.arrayRemove([uid])
        });
      }

      debugPrint("User removed from activity successfully.");
    } catch (e) {
      debugPrint('Error removing user from activity: $e');
    }
  }

  Future getGroupAdmin(String activityId) async {
    DocumentSnapshot documentSnapshot = await _getActivityDoc(activityId);
    return documentSnapshot['admin'];
  }

// #endregion

// #region Chatting

  Future<Widget> getChatPage(String activityId) async {
    try {
      Widget widget = const IndexPage();

      await _personalOrCommercial(
          activityId,
          (a) => widget = ChatPage(activity: a),
          (comA) => widget = ComChatPage(activity: comA));

      return widget;
    } catch (e) {
      debugPrint('Error getting chat page: $e');
      return const IndexPage();
    }
  }

  getChats(String activityId, [bool commercial = false]) async {
    DocumentReference docRef = commercial
        ? _comActivityDocRef(activityId)
        : _activityDocRef(activityId);
    return docRef
        .collection('messages')
        .orderBy('time', descending: true)
        .snapshots();
  }

  void sendMessage(String activityId, Map<String, dynamic> chatMessageData,
      [bool commercial = false]) async {
    DocumentReference docRef = commercial
        ? _comActivityDocRef(activityId)
        : _activityDocRef(activityId);
    await docRef.collection("messages").add(chatMessageData);

    await docRef.update({
      "recentMessage": chatMessageData['message'],
      "recentMessageSender": chatMessageData['sender'],
      "recentMessageTime": chatMessageData['time'].toString(),
    });
  }

// #endregion

// #region ThisUser

  Future<bool> checkExistingUser() async {
    return await _tryGetUser(uid, (user) {}, () {});
  }

  Future<bool> checkAnonymousUser() async {
    MiittiUser? user = await getUser(uid);
    if (user == null) {
      return true;
    } else if (user.userArea.isEmpty) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> saveUserDatatoFirebase({
    required BuildContext context,
    required MiittiUser userModel,
    required File? image,
    required Function onSuccess,
  }) async {
    try {
      OtherWidgets.showLoadingDialog(context);
      await uploadUserImage(_firebaseAuth.currentUser!.uid, image)
          .then((value) {
        userModel.profilePicture = value;
      }).onError((error, stackTrace) {});
      userModel.userRegistrationDate =
          DateFormat('dd/MM/yyyy').format(DateTime.now());
      userModel.userPhoneNumber = _firebaseAuth.currentUser!.phoneNumber ?? '';
      userModel.uid = _firebaseAuth.currentUser!.uid;
      _uid = userModel.uid;
      _miittiUser = userModel;

      await _userDocRef(userModel.uid)
          .set(userModel.toMap())
          .then((value) async {
        onSuccess();
      }).onError(
        (error, stackTrace) {
          debugPrint('Error saving user data: $error');
        },
      );
    } on FirebaseAuthException catch (e) {
      showSnackBar(context,
          "Datan tallennus epäonnistui: ${e.message.toString()}", AppStyle.red);
      debugPrint("Userdata to firebase error: $e");
    } catch (e) {
      debugPrint("Userdata to firebase error: $e");
    } finally {
      Navigator.of(context).pop();
    }
  }

  /*Future<void> saveAnonUserToFirebase({
    required BuildContext context,
    required Function onSucess,
  }) async {
    try {
      OtherWidgets().showLoadingDialog(context);

      MiittiUser userModel = MiittiUser(
        userName: '',
        userEmail: '',
        uid: uid,
        userPhoneNumber: '+358000000000',
        userBirthday: '',
        userArea: '',
        userFavoriteActivities: {},
        userChoices: {},
        userGender: '',
        userLanguages: {},
        profilePicture: '',
        invitedActivities: {},
        userStatus: '',
        userSchool: '',
        fcmToken: '',
        userRegistrationDate: DateFormat('dd/MM/yyyy').format(DateTime.now()),
      );

      _miittiUser = userModel;

      await _userDocRef(uid).set(userModel.toMap()).then((value) async {
        onSucess();
      }).onError(
        (error, stackTrace) {},
      );
    } on FirebaseAuthException catch (e) {
      showSnackBar(context, e.message.toString(), Colors.red.shade800);
      debugPrint("Userdata to firebase error: $e");
    } finally {
      Navigator.of(context);
    }
  }*/

  Future<String> uploadUserImage(String uid, File? image) async {
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      // contentType: 'image/png',
      customMetadata: {'picked-file-path': image!.path},
    );

    String filePath = 'userImages/$uid/profilePicture.jpg';
    try {
      final UploadTask uploadTask;
      Reference ref = FirebaseStorage.instance.ref(filePath);

      uploadTask = ref.putData(await image.readAsBytes(), metadata);

      String imageUrl = await (await uploadTask).ref.getDownloadURL();

      return imageUrl;
    } catch (error) {
      throw Exception("Upload failed: $error");
    }
  }

  Future saveUserDataToSP() async {
    SharedPreferences s = await SharedPreferences.getInstance();
    await s.setString('user_model', json.encode(miittiUser.toMap()));
  }

  Future getDataFromSp() async {
    SharedPreferences s = await SharedPreferences.getInstance();
    _isAnonymous = s.getBool('is_anonymous') ?? true;
    if (!isAnonymous) {
      String data = s.getString('user_model') ?? '';
      _miittiUser = MiittiUser.fromMap(jsonDecode(data));
      _uid = _miittiUser!.uid;
    } else {
      _uid = _firebaseAuth.currentUser!.uid;
    }
    notifyListeners();
  }

  Future getDataFromFirestore() async {
    await _getUserDoc(_firebaseAuth.currentUser!.uid)
        .then((DocumentSnapshot snapshot) {
      _miittiUser = MiittiUser(
          userName: snapshot['userName'],
          userEmail: snapshot['userEmail'],
          uid: snapshot['uid'],
          userPhoneNumber: snapshot['userPhoneNumber'],
          userBirthday: snapshot['userBirthday'],
          userArea: snapshot['userArea'],
          userFavoriteActivities:
              (snapshot['userFavoriteActivities'] as List<dynamic>)
                  .cast<String>()
                  .toSet(),
          userChoices: (snapshot['userChoices'] as Map<String, dynamic>)
              .cast<String, String>(),
          userGender: snapshot['userGender'],
          userLanguages: (snapshot['userLanguages'] as List<dynamic>)
              .cast<String>()
              .toSet(),
          profilePicture: snapshot['profilePicture'],
          invitedActivities: (snapshot['invitedActivities'] as List<dynamic>)
              .cast<String>()
              .toSet(),
          userStatus: snapshot['userStatus'],
          userSchool: snapshot['userSchool'],
          fcmToken: snapshot['fcmToken'],
          userRegistrationDate: snapshot['userRegistrationDate']);
      _uid = _miittiUser!.uid;
    }).onError((error, stackTrace) {
      debugPrint('ERROR: ${error.toString()}');
    });
  }

  Future<void> setUserStatus() async {
    if (_isAnonymous) return;
    try {
      DateTime now = DateTime.now().toUtc();
      String timestampString = now.toIso8601String();
      await _userDocRef(uid).update({'userStatus': timestampString});
      debugPrint("Userstatus set");
    } catch (e, s) {
      if (_uid == null) debugPrint("UID is null");
      debugPrint('Got an error setting user status $e and my uid is $_uid');
      debugPrint('$s');
    }
  }

  Future userSignOut() async {
    SharedPreferences s = await SharedPreferences.getInstance();
    await _firebaseAuth.signOut();
    _isSignedIn = false;
    notifyListeners();
    s.clear();
  }

  Future updateUserInfo({
    required MiittiUser updatedUser,
    BuildContext? context,
    File? imageFile,
  }) async {
    try {
      if (context != null && context.mounted) {
        OtherWidgets.showLoadingDialog(context);
      }
      if (imageFile != null) {
        await uploadUserImage(_firebaseAuth.currentUser!.uid, imageFile)
            .then((value) {
          updatedUser.profilePicture = value;
        });
      }

      await _fireStore
          .collection('users')
          .doc(_uid)
          .update(updatedUser.toMap())
          .then((value) {
        _miittiUser = updatedUser;
      });

      // Update the user in the provider
    } on FirebaseAuthException catch (e) {
      debugPrint('Error updating user info: ${e.message}');
    } finally {
      if (context != null && context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<(bool logOut, String message)> removeUser(String userId) async {
    //Deleting user image from storage
    try {
      await FirebaseStorage.instance
          .ref('userImages/$userId/profilePicture.jpg')
          .delete();
      debugPrint("Deleted from storage");
    } catch (e, s) {
      debugPrint("Error removing user image from storage: $e");
      await FirebaseCrashlytics.instance
          .recordError(e, s, reason: 'a non-fatal error');
      return (
        false,
        "Profiilikuvan poistaminen palvelimelta epäonnistui.\nOle yhteydessä tukeen."
      );
    }

    //Deleting userdata from firestore
    try {
      await _userDocRef(userId).delete();
      debugPrint("Deteted from firestore");
    } catch (e, s) {
      debugPrint("Error removing user from firestore: $e");
      await FirebaseCrashlytics.instance
          .recordError(e, s, reason: 'a non-fatal error');
      return (
        false,
        "Profiilin poistaminen palvelimelta epäonnistui.\nOle yhteydessä tukeen."
      );
    }

    //Deleting user from auth
    try {
      if (!adminId.contains(_firebaseAuth.currentUser!.uid) &&
          _firebaseAuth.currentUser!.uid.isNotEmpty) {
        await _firebaseAuth.currentUser?.delete();
        debugPrint("deleted from auth");
      }
    } catch (e, s) {
      debugPrint("Error removing user from auth: $e");
      await FirebaseCrashlytics.instance
          .recordError(e, s, reason: 'a non-fatal error');
      return (
        false,
        "Profiili poistettiin palvelimelta mutta kirjautumistietojen poistaminen epäonnistui.\nOle yhteydessä tukeen."
      );
    }

    try {
      if (!adminId.contains(userId)) {
        SharedPreferences s = await SharedPreferences.getInstance();
        _isSignedIn = false;
        await s.clear().then((v) {
          if (v) {
            debugPrint("deleted from shared pref");
          } else {
            debugPrint("not deleted from shared pref");
            return (
              false,
              "Tilisi on poistettu palvelimelta, mutta tietojen poistaminen puhelimelta epäonnistui.\n Poista sovelluksen tiedot puhelimen asetuksista."
            );
          }
        });
      }
    } catch (e, s) {
      debugPrint("Error removing user from the device $e");
      await FirebaseCrashlytics.instance
          .recordError(e, s, reason: 'a non-fatal error');
      return (
        false,
        "Tilisi on poistettu palvelimelta, mutta tietojen poistaminen laitteelta epäonnistui.\n Poista sovelluksen tiedot puhelimen asetuksista.'"
      );
    }
    return (true, "Tilisi on poistettu onnistuneesti");
  }

// #endregion

// #region Users

  Future<List<MiittiUser>> fetchUsers() async {
    QuerySnapshot querySnapshot = await _getFireQuery(_usersString);

    return querySnapshot.docs.map((doc) => MiittiUser.fromDoc(doc)).toList();
  }

  Future<QuerySnapshot> lazyFilteredUsers(int type, int batchSize,
      [DocumentSnapshot? startAfter]) {
    Query query = _fireStore.collection(_usersString);

    if (type == 0) {
      query = query.where('userArea', isEqualTo: miittiUser.userArea);
    } else if (type == 1) {
      query = query.where('userFavoriteActivities',
          arrayContainsAny: miittiUser.userFavoriteActivities);
    } else {
      query = query.orderBy('userRegistrationDate', descending: true);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.limit(batchSize).get();
  }

  Future<MiittiUser?> getUser(String id) async {
    DocumentSnapshot doc = await _getUserDoc(id);
    if (!doc.exists) {
      return null;
    }
    MiittiUser user = MiittiUser.fromDoc(doc);
    return user;
  }

  Future<CommercialUser> getCommercialUser(String id) async {
    DocumentSnapshot doc =
        await _fireStore.collection("commercialUsers").doc(id).get();
    CommercialUser user =
        CommercialUser.fromMap(doc.data() as Map<String, dynamic>);

    return user;
  }

  Future<List<MiittiUser>> fetchUsersByActivityId(String activityId) async {
    try {
      // Fetch activity by id
      MiittiActivity activity =
          await _personalOrCommercial(activityId, (personActivity) async {
        return fetchUsersByUids(personActivity.participants);
      }, (commercialActivity) async {
        return fetchUsersByUids(commercialActivity.participants);
      });
      return fetchUsersByUids(activity.participants);
    } catch (e, s) {
      debugPrint("Error fetching users by activity id: $e, stack: $s");
      return [];
    }
  }

  Future<List<MiittiUser>> fetchUsersByUids(Set<String> userIds) async {
    try {
      List<MiittiUser> users = [];
      for (final uid in userIds) {
        await _tryGetUser(
            uid, (user) => users.add(user), () => debugPrint("User not found"));
      }
      return users;
    } catch (e) {
      debugPrint("Error fetching users: $e");
      return [];
    }
  }
// #endregion

// #region Utils

  Future<QuerySnapshot> _getFireQuery(String collection) {
    return _fireStore.collection(collection).get();
  }

  Future<QuerySnapshot> _queryWhereContains(
      String collection, String array, String value) {
    return _fireStore
        .collection(collection)
        .where(array, arrayContains: value)
        .get();
  }

  Future<QuerySnapshot> _queryWhereEquals(
      String collection, String field, String value) {
    return _fireStore
        .collection(collection)
        .where(field, isEqualTo: value)
        .get();
  }

  DocumentReference _userDocRef(String userId) {
    return _fireStore.collection(_usersString).doc(userId);
  }

  Future<DocumentSnapshot> _getUserDoc(String userId) {
    return _fireStore.collection(_usersString).doc(userId).get();
  }

  Future<DocumentSnapshot> _getActivityDoc(String activityId) {
    return _fireStore.collection(_activitiesString).doc(activityId).get();
  }

  DocumentReference _activityDocRef(String activityId) {
    return _fireStore.collection(_activitiesString).doc(activityId);
  }

  DocumentReference _comActivityDocRef(String activityId) {
    return _fireStore.collection(_comactString).doc(activityId);
  }

  Future<bool> _tryGetUser(String userId, Function(MiittiUser user) exists,
      Function notFound) async {
    DocumentSnapshot snapshot = await _getUserDoc(userId);
    if (snapshot.exists) {
      await exists(MiittiUser.fromDoc(snapshot));
      return true;
    } else {
      await notFound();

      return false;
    }
  }

  Future<MiittiActivity> _personalOrCommercial(
      String activityId,
      Function(PersonActivity activity) isPersonal,
      Function(CommercialActivity comActivity) isCommercial) async {
    DocumentSnapshot snapshot = await _getActivityDoc(activityId);
    if (snapshot.exists) {
      PersonActivity activity = PersonActivity.fromDoc(snapshot);
      isPersonal(activity);
      return activity;
    } else {
      debugPrint("is commercial");
      DocumentSnapshot comSnapshot = await _comActivityDocRef(uid).get();
      CommercialActivity commercialActivity =
          CommercialActivity.fromDoc(comSnapshot);
      isCommercial(commercialActivity);
      return commercialActivity;
    }
  }

// #endregion
}
