import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/functions/filter_settings.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:miitti_app/models/ad_banner.dart';
import 'package:miitti_app/models/commercial_activity.dart';
import 'package:miitti_app/models/commercial_spot.dart';
import 'package:miitti_app/models/commercial_user.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/models/person_activity.dart';
import 'package:miitti_app/models/report.dart';
import 'package:miitti_app/screens/index_page.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/other_widgets.dart';

import '../screens/activity_details_page.dart';

// A class for interfacing with the Firebase Firestore service
class FirestoreService {
  static const String _usersString = 'users';
  static const String _activitiesString = 'activities';
  static const String _comactString = 'commercialActivities';

  final FirebaseFirestore _firestore;
  final Ref ref;

  MiittiUser? _miittiUser;
  MiittiUser? get miittiUser => _miittiUser;
  bool get isAnonymous => _miittiUser == null;
  String? get uid => _miittiUser?.uid;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  FirestoreService(this.ref) : _firestore = FirebaseFirestore.instance;

  //PUBLIC METHODS

  Future<bool> saveUserData({
  required MiittiUser userModel,
  required File? image,
}) async {
  try {
    final uid = ref.read(userStateProvider.notifier).uid;
    final imageUrl = await ref.read(firebaseStorageServiceProvider).uploadUserImage(uid!, image);
      userModel.profilePictures[0] = imageUrl;

    userModel.registrationDate = DateTime.now();
    _miittiUser = userModel;

    await _firestore.collection(_usersString).doc(userModel.uid).set(userModel.toMap());
    return true;
  } catch (e) {
    debugPrint("Error saving user data: $e");
    return false;
  }
}





















  void reset() {
    _miittiUser = null;
  }

  Future<bool> checkExistingUser(String userId) async {
    return _wait(() => _tryGetUser(userId, exists: (miittiUser) =>
          _miittiUser = miittiUser
        ));
  }

  Future<MiittiUser?> getUser(String userId) async {
    MiittiUser? user;
    _wait(
      () => _tryGetUser(userId, exists: (miittiUser) {
        user = miittiUser;
      }),
    );
    return user;
  }

  Future<void> updateUser(Map<String, dynamic> data, {uid = "current"}) async {
    if (isAnonymous) {
      debugPrint("Cannot update anonymous user");
      return;
    }
    try {
      if (uid == "current") {
        uid = this.uid;
        _miittiUser!.updateUser(data);
      }
      await _firestore.collection(_usersString).doc(uid).update(data);
    } catch (e, s) {
      debugPrint('Got an error updating user $e');
      debugPrint('$s');
    }
  }

  void reportActivity(String activity, String message) async {
    if (isAnonymous) {
      debugPrint("Anonymous user cannot report activity");
      return;
    }

    try {
      DocumentReference docRef =
          _firestore.collection('reportedActivities').doc(activity);
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot documentSnapshot = await transaction.get(docRef);

        if (documentSnapshot.exists) {
          transaction.update(docRef, {
            'reasons': FieldValue.arrayUnion(["$uid: $message"]),
          });
        } else {
          transaction.set(docRef, {
            'reportedId': activity,
            'reasons': ["$uid: $message"],
            'isUser': false,
          });
        }
      });
    } catch (e) {
      debugPrint("Reporting failed: $e");
      updateUser({'lastActivity': activity});
    }
  }

  Future<void> deleteUser({String? uid}) async {
    uid ??= this.uid;
    if (isAnonymous) {
      debugPrint("Cannot delete anonymous user");
      return;
    }
    try {
      await _firestore.collection(_usersString).doc(uid).delete();
      _miittiUser = null;
    } catch (e) {
      debugPrint('Got an error deleting user $e');
    }
  }

  Future<UserStatusInActivity> joinOrRequestActivity(String activityId) async {
    if (isAnonymous) {
      debugPrint("Anonymous user cannot join or request activities");
      return UserStatusInActivity.none;
    }
    if (miittiUser!.invitedActivities.contains(activityId)) {
      await reactToInvite(activityId, true);
      return UserStatusInActivity.joined;
    } else {
      await sendActivityRequest(activityId);
      return UserStatusInActivity.requested;
    }
  }

  Future reactToInvite(String activityId, bool accepted) async {
    try {
      await updateUser({
        'invitedActivities': FieldValue.arrayRemove([activityId])
      });
      if (accepted) {
        await updateUserJoiningActivity(activityId, uid!, true);
      }
    } catch (e) {
      debugPrint('Found error accepting invite: $e');
    }
  }

  Future<void> sendActivityRequest(String activityId) async {
    try {
      await _firestore.collection(_activitiesString).doc(activityId).update({
        'requests': FieldValue.arrayUnion([uid])
      }).then((value) {
        debugPrint("User joined the activity successfully");
      }).catchError((error) {
        debugPrint("Error joining the activity: $error");
      });
    } catch (e) {
      debugPrint('Error while joining activity: $e');
    }
  }

  Future<bool> updateUserJoiningActivity(
    String activityId,
    String userId,
    bool accept,
  ) async {
    bool joined = false;

    try {
      final activityRef = _firestore.collection('activities').doc(activityId);

      await _firestore.runTransaction((transaction) async {
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

  Future<List<MiittiUser>> fetchUsersByUids(List<String> userIds) async {
    try {
      var result = await _firestore
          .collection(_usersString)
          .where('uid', whereIn: userIds)
          .get();
      return result.docs.map((doc) => MiittiUser.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint("Error fetching users: $e");
      return [];
    }
  }

  Future<MiittiActivity> getSingleActivity(String activityId) async {
    MiittiActivity activity;

    activity = await _personalOrCommercial(activityId, (a) {}, (comA) {});

    return activity;
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
            activity.adminGender != miittiUser!.gender) {
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
          debugPrint("Checking filters of ${_miittiUser?.name}");
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

  Future<void> removeActivity(String activityId) async {
    try {
      await _firestore.collection(_activitiesString).doc(activityId).delete();
    } catch (e) {
      debugPrint('Error while removing activity: $e');
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

  Future<List<MiittiUser>> fetchUsers() async {
    QuerySnapshot querySnapshot = await _getFireQuery(_usersString);

    return querySnapshot.docs.map((doc) => MiittiUser.fromFirestore(doc)).toList();
  }

  Future<List<PersonActivity>> fetchActivitiesRequestsFrom(
      String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
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

  Future<QuerySnapshot> lazyFilteredUsers(int type, int batchSize,
      [DocumentSnapshot? startAfter]) {
    Query query = _firestore.collection(_usersString);

    if (type == 0) {
      query = query.where('userArea', isEqualTo: miittiUser!.areas);
    } else if (type == 1) {
      query = query.where('userFavoriteActivities',
          arrayContainsAny: miittiUser!.favoriteActivities);
    } else {
      query = query.orderBy('userRegistrationDate', descending: true);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.limit(batchSize).get();
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
      await _firestore.collection('adBanners').doc(adUid).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error adding view: $e');
    }
  }

  Future<List<MiittiActivity>> fetchUserActivities() async {
    try {
      QuerySnapshot querySnapshot =
          await _queryWhereContains(_activitiesString, 'participants', uid!);

      QuerySnapshot commercialSnapshot =
          await _queryWhereContains(_comactString, 'participants', uid!);

      QuerySnapshot requestSnapshot =
          await _queryWhereContains(_activitiesString, "requests", uid!);

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

      if (miittiUser!.invitedActivities.isNotEmpty) {
        for (String activityId in miittiUser!.invitedActivities) {
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

  Future<List<Map<String, dynamic>>> fetchActivitiesRequests() async {
    try {
      QuerySnapshot querySnapshot =
          await _queryWhereEquals(_activitiesString, 'admin', uid!);

      List<PersonActivity> activities =
          querySnapshot.docs.map((doc) => PersonActivity.fromDoc(doc)).toList();

      List<Map<String, dynamic>> usersAndActivityIds = [];

      for (PersonActivity activity in activities) {
        List<MiittiUser> users =
            await fetchUsersByUids(activity.requests.toList());
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

  Future updateUserInfo({
    required MiittiUser updatedUser,
    BuildContext? context,
    File? imageFile,
  }) async {
    try {
      if (context != null && context.mounted) {
        showLoadingDialog(context);
      }
      if (imageFile != null) {
        await uploadUserImage(ref.read(userStateProvider.notifier).uid!, imageFile)
            .then((value) {
          updatedUser.profilePictures[0] = value;
        });
      }

      await _firestore
          .collection('users')
          .doc(uid)
          .update(updatedUser.toMap())
          .then((value) {
        _miittiUser = updatedUser;
      });

      // Update the user in the provider
    } catch (e) {
      debugPrint('Error updating user info: $e');
    } finally {
      if (context != null && context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> saveMiittiActivityDataToFirebase({
    required BuildContext context,
    required PersonActivity activityModel,
  }) async {
    showLoadingDialog(context);
    try {
      activityModel.admin = _miittiUser!.uid;
      activityModel.adminAge = calculateAge(_miittiUser!.birthday);
      activityModel.adminGender = _miittiUser!.gender.name;
      activityModel.activityUid = generateCustomId();
      activityModel.participants.add(_miittiUser!.uid);

      await _activityDocRef(activityModel.activityUid)
          .set(activityModel.toMap())
          .then((value) {
        showSnackBar(context, 'Miittisi on luotu onnistuneesti!', Colors.green);

        pushNRemoveUntil(context, const IndexPage());
      });
    } catch (e) {
      showSnackBar(context, e.toString(), AppStyle.red);
      context.go('/');
    }
  }

  Future<CommercialUser> getCommercialUser(String id) async {
    DocumentSnapshot doc =
        await _firestore.collection("commercialUsers").doc(id).get();
    CommercialUser user =
        CommercialUser.fromMap(doc.data() as Map<String, dynamic>);

    return user;
  }

  Future<void> joinCommercialActivity(String activityId) async {
    try {
      await _comActivityDocRef(activityId).update({
        'participants': FieldValue.arrayUnion([uid!])
      }).then((value) {
        debugPrint("User joined the activity successfully");
      }).catchError((error) {
        debugPrint("Error joining the activity: $error");
      });
    } catch (e) {
      debugPrint('Error while joining activity: $e');
    }
  }

  Future<bool> checkIfUserJoined(String activityUid,
      {bool commercial = false}) async {
    final snapshot = await _firestore
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

  getChats(String activityId, [bool commercial = false]) async {
    DocumentReference docRef = commercial
        ? _comActivityDocRef(activityId)
        : _activityDocRef(activityId);
    return docRef
        .collection('messages')
        .orderBy('time', descending: true)
        .snapshots();
  }

  Future<void> reportUser(String message, String reportedId) async {
    try {
      _isLoading = true;

      String senderId = uid!;

      DocumentSnapshot documentSnapshot =
          await _firestore.collection('reportedUsers').doc(reportedId).get();

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
      await _firestore
          .collection('reportedUsers')
          .doc(reportedId)
          .set(report.toMap());
    } catch (e) {
      debugPrint("Reporting failed: $e");
    } finally {
      _isLoading = false;
    }
  }

  //PRIVATE UTILS

  Future<bool> _tryGetUser(String userId, {Function(MiittiUser user)? exists, Function? notFound}) async {
    DocumentSnapshot snapshot = await _getUserDoc(userId);
    if (snapshot.exists) {
      if (exists != null) {
        try {
          MiittiUser user = MiittiUser.fromFirestore(snapshot);
          exists(user);
        } catch (e) {
          debugPrint('Error running function for existing user: $e');
        }
      }
      return true;
    } else {
      if (notFound != null) {
        await notFound();
      }
      return false;
    }
  }

  Future<List<PersonActivity>> fetchAdminActivities() async {
    try {
      QuerySnapshot querySnapshot =
          await _queryWhereEquals(_activitiesString, 'admin', uid!);

      List<PersonActivity> activities =
          querySnapshot.docs.map((doc) => PersonActivity.fromDoc(doc)).toList();

      return activities;
    } catch (e) {
      debugPrint('Error fetching user activities: $e');
      return [];
    }
  }

  Future<T> _wait<T>(Function action) async {
    _isLoading = true;
    T result = await action();
    _isLoading = false;
    return result;
  }

  Future<QuerySnapshot> _getFireQuery(String collection) {
    return _firestore.collection(collection).get();
  }

  Future<DocumentSnapshot> _getUserDoc(String userId) {
    return _firestore.collection(_usersString).doc(userId).get();
  }

  Future<DocumentSnapshot> _getActivityDoc(String activityId) {
    return _firestore.collection(_activitiesString).doc(activityId).get();
  }

  DocumentReference _userDocRef(String userId) {
    return _firestore.collection(_usersString).doc(userId);
  }

  DocumentReference _activityDocRef(String activityId) {
    return _firestore.collection('activities').doc(activityId);
  }

  DocumentReference _comActivityDocRef(String activityId) {
    return _firestore.collection('commercialActivities').doc(activityId);
  }

  Future<QuerySnapshot> _queryWhereContains(
      String collection, String array, String value) {
    return _firestore
        .collection(collection)
        .where(array, arrayContains: value)
        .get();
  }

  Future<QuerySnapshot> _queryWhereEquals(
      String collection, String field, String value) {
    return _firestore
        .collection(collection)
        .where(field, isEqualTo: value)
        .get();
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
      DocumentSnapshot comSnapshot = await _comActivityDocRef(activityId).get();
      CommercialActivity commercialActivity =
          CommercialActivity.fromDoc(comSnapshot);
      isCommercial(commercialActivity);
      return commercialActivity;
    }
  }

  inviteUserToYourActivity(String uid, String activityUid) {}
}
