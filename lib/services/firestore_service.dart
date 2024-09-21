import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:miitti_app/models/ad_banner_data.dart';
import 'package:miitti_app/models/commercial_activity.dart';
import 'package:miitti_app/models/commercial_spot.dart';
import 'package:miitti_app/models/commercial_user.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/models/user_created_activity.dart';
import 'package:miitti_app/state/activities_filter_settings.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/other_widgets.dart';
import 'package:rxdart/rxdart.dart';

import '../screens/activity_details_page.dart';

// A class for interfacing with the Firebase Firestore service
class FirestoreService {
  static const String _usersCollection = 'users';
  static const String _activitiesCollection = 'activities';
  static const String _commercialActivitiesCollection = 'commercialActivities';
  static const String _adBannersCollection = 'adBanners';

  final FirebaseFirestore _firestore;
  final Ref ref;
  DocumentSnapshot? _lastUserActivityDocument;
  DocumentSnapshot? _lastCommercialActivityDocument;

  // TODO: Delete when redundant
  MiittiUser? _miittiUser;
  MiittiUser? get miittiUser => _miittiUser;
  bool get isAnonymous => _miittiUser == null;
  String? get uid => _miittiUser?.uid;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  FirestoreService(this.ref) : _firestore = FirebaseFirestore.instance{
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  Future<bool> saveUserData({required MiittiUser userModel, required File? image}) async {
    try {
      final imageUrl = await ref.read(firebaseStorageServiceProvider).uploadProfilePicture(userModel.uid, image);
      userModel.profilePicture = imageUrl;
      await _firestore.collection(_usersCollection).doc(userModel.uid).set(userModel.toMap());
      _miittiUser = userModel; // TODO: Delete when redundant
      return true;
    } catch (e) {
      debugPrint("Error saving user data: $e");
      return false;
    }
  }
  
  Future<MiittiUser?> loadUserData(String userId) async {
    DocumentSnapshot snapshot = await _firestore.collection(_usersCollection).doc(userId).get();
    if (snapshot.exists) {
      _miittiUser = MiittiUser.fromFirestore(snapshot); // TODO: Delete when redundant
      return MiittiUser.fromFirestore(snapshot);
    } else {
      return null;
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      final participantQuery = _firestore.collection(_activitiesCollection).where('participants', arrayContains: uid);
      final requestQuery = _firestore.collection(_activitiesCollection).where('requests', arrayContains: uid);
      final creatorQuery = _firestore.collection(_activitiesCollection).where('creator', isEqualTo: uid);

      final commercialParticipantQuery = _firestore.collection(_commercialActivitiesCollection).where('participants', arrayContains: uid);

      // Delete the deleted user from participants list in activities where they are a participant
      for (DocumentSnapshot doc in (await participantQuery.get()).docs) {
        final activity = UserCreatedActivity.fromFirestore(doc);
        await doc.reference.update(activity.removeParticipant(uid));
      }

      // Delete the deleted user from requests list in activities where they requested to join
      for (DocumentSnapshot doc in (await requestQuery.get()).docs) {
        final activity = UserCreatedActivity.fromFirestore(doc);
        await doc.reference.update(activity.removeRequest(uid));
      }

      // Archive activities where the deleted user is the creator and where there are no participants by setting their endTime to now
      for (DocumentSnapshot doc in (await creatorQuery.get()).docs) {
        final activity = UserCreatedActivity.fromFirestore(doc);
        activity.removeParticipant(uid);
        activity.endTime = DateTime.now();
        await doc.reference.update(activity.toMap());
      }

      // Delete the deleted user from participants list in commercial activities where they are a participant
      for (DocumentSnapshot doc in (await commercialParticipantQuery.get()).docs) {
        final commercialActivity = CommercialActivity.fromFirestore(doc);
        await doc.reference.update(commercialActivity.removeParticipant(uid));
      }

      await _firestore.collection(_usersCollection).doc(uid).delete();
      _miittiUser = null; // TODO: Delete when redundant

    } catch (e) {
      debugPrint('Got an error deleting user $e');
    }
  }


  Future<List<MiittiActivity>> fetchFilteredActivities({
    int pageSize = 10,
    bool fullRefresh = false,
  }) async {
    try {
      debugPrint('Fetching $pageSize activities');

      if (fullRefresh) {
        _lastUserActivityDocument = null;
        _lastCommercialActivityDocument = null;
      }

      // Load user state and filter settings
      final userState = ref.read(userStateProvider);
      ref.read(activitiesFilterSettingsProvider.notifier).loadPreferences();
      final filterSettings = ref.read(activitiesFilterSettingsProvider);

      // Query for user activities
      Query userActivitiesQuery = _firestore.collection(_activitiesCollection)
        .where(Filter.or(
          Filter('endTime', isNull: true),
          Filter('endTime', isGreaterThanOrEqualTo: DateTime.now()))
        )
        .where('creatorAge', isGreaterThanOrEqualTo: filterSettings.minAge)
        .where('creatorAge', isLessThanOrEqualTo: filterSettings.maxAge)
        .where('maxParticipants', isLessThanOrEqualTo: filterSettings.maxParticipants)
        .where('maxParticipants', isGreaterThanOrEqualTo: filterSettings.minParticipants);

      // Apply additional filters
      if (filterSettings.categories.isNotEmpty) {
        userActivitiesQuery = userActivitiesQuery.where('category', whereIn: filterSettings.categories);
      }
      if (filterSettings.languages.isNotEmpty) {
        userActivitiesQuery = userActivitiesQuery.where('creatorLanguages', arrayContainsAny: filterSettings.languages);
      }
      if (filterSettings.onlySameGender) {
        userActivitiesQuery = userActivitiesQuery.where('creatorGender', isEqualTo: userState.data.gender!.name);
      }
      if (!filterSettings.includePaid) {
        userActivitiesQuery = userActivitiesQuery.where('paid', isEqualTo: false);
      }
      userActivitiesQuery = userActivitiesQuery.orderBy('creationTime', descending: true);

      // Handle pagination for user activities
      if (_lastUserActivityDocument != null) {
        userActivitiesQuery = userActivitiesQuery.startAfter([(_lastUserActivityDocument!.data() as Map<String, dynamic>)['creationTime']]);
      }

      // Fetch user activities
      QuerySnapshot userActivitiesSnapshot = await userActivitiesQuery.limit(pageSize).get();
      List<MiittiActivity> userActivities = userActivitiesSnapshot.docs.map((doc) => UserCreatedActivity.fromFirestore(doc)).toList();

      // Update last user activity document
      if (userActivities.isNotEmpty) {
        _lastUserActivityDocument = userActivitiesSnapshot.docs.last;
      }

      // Query for commercial activities
      Query commercialActivitiesQuery = _firestore.collection(_commercialActivitiesCollection).orderBy('creationTime', descending: true);

      // Handle pagination for commercial activities
      if (_lastCommercialActivityDocument != null) {
        commercialActivitiesQuery = commercialActivitiesQuery.startAfter([(_lastCommercialActivityDocument!.data() as Map<String, dynamic>)['creationTime']]);
      }

      QuerySnapshot commercialActivitiesSnapshot = await commercialActivitiesQuery.limit(pageSize).get();
      List<MiittiActivity> commercialActivities = commercialActivitiesSnapshot.docs.map((doc) {
        final commercialActivity = CommercialActivity.fromFirestore(doc);
        incrementCommercialActivityViewCounter(commercialActivity.id);
        return commercialActivity;
      }).toList();

      // Update last commercial activity document
      if (commercialActivities.isNotEmpty) {
        _lastCommercialActivityDocument = commercialActivitiesSnapshot.docs.last;
      }

      // Combine user and commercial activities
      List<MiittiActivity> activities = List<MiittiActivity>.from(userActivities);
      activities.addAll(commercialActivities);

      return activities;
    } catch (e) {
      debugPrint('Error fetching activities: $e');
      return [];
    }
  }






  // Stream<List<MiittiActivity>> streamFilteredActivities(LatLng center, double radius) {
  //   final filterSettings = ref.read(activitiesFilterSettingsProvider);
  //   final userState = ref.read(userStateProvider);

  //   final collectionRef = _firestore.collection(_activitiesCollection);
  //   final geoRef = GeoCollectionReference<Map<String, dynamic>>(collectionRef);

  //   final GeoFirePoint centerPoint = GeoFirePoint(GeoPoint(center.latitude, center.longitude));

  //   Query<Map<String, dynamic>> queryBuilder(Query<Map<String, dynamic>> query) {
  //     query = query.where('endTime', isNull: true)
  //                  .where('endTime', isGreaterThanOrEqualTo: DateTime.now())
  //                  .where('creatorAge', isGreaterThanOrEqualTo: filterSettings.minAge)
  //                  .where('creatorAge', isLessThanOrEqualTo: filterSettings.maxAge)
  //                  .where('maxParticipants', isLessThanOrEqualTo: filterSettings.maxParticipants)
  //                  .where('maxParticipants', isGreaterThanOrEqualTo: filterSettings.minParticipants);

  //     if (filterSettings.categories.isNotEmpty) {
  //       query = query.where('category', whereIn: filterSettings.categories);
  //     }

  //     if (filterSettings.languages.isNotEmpty) {
  //       query = query.where('creatorLanguages', arrayContainsAny: filterSettings.languages);
  //     }

  //     if (filterSettings.onlySameGender) {
  //       query = query.where('creatorGender', isEqualTo: userState.data.gender!.name);
  //     }

  //     if (!filterSettings.includePaid) {
  //       query = query.where('paid', isEqualTo: false);
  //     }

  //     return query;
  //   }

  //   GeoPoint geopointFrom(Map<String, dynamic> data) =>
  //       (data['location'] as Map<String, dynamic>)['geopoint'] as GeoPoint;

  //   final Stream<List<DocumentSnapshot<Map<String, dynamic>>>> stream = geoRef.subscribeWithin(
  //     center: centerPoint,
  //     radiusInKm: radius,
  //     field: 'location',
  //     geopointFrom: geopointFrom,
  //     queryBuilder: queryBuilder,
  //   );

  //   return stream.asyncMap((querySnapshot) async {
  //     List<MiittiActivity> activities = querySnapshot.map((doc) => UserCreatedActivity.fromFirestore(doc)).toList();

  //     QuerySnapshot commercialQuery = await _firestore.collection(_commercialActivitiesCollection).get();
  //     List<MiittiActivity> commercialActivities = commercialQuery.docs.map((doc) => CommercialActivity.fromFirestore(doc)).toList();

  //     List<MiittiActivity> list = List<MiittiActivity>.from(activities);
  //     list.addAll(List<MiittiActivity>.from(commercialActivities));
  //     return list;
  //   });
  // }

  Stream<List<MiittiActivity>> streamActivitiesWithinRadius(LatLng center, double radiusInKm) {
    final geoCollectionReference = GeoCollectionReference(_firestore.collection(_activitiesCollection));
    final commercialGeoCollectionReference = GeoCollectionReference(_firestore.collection(_commercialActivitiesCollection));
    final filterSettings = ref.read(activitiesFilterSettingsProvider);
    final userState = ref.read(userStateProvider);

    Query<Map<String, dynamic>> queryBuilder(Query<Map<String, dynamic>> query) {
      query = query
        .where('creatorAge', isGreaterThanOrEqualTo: filterSettings.minAge)
        .where('creatorAge', isLessThanOrEqualTo: filterSettings.maxAge)
        .where('maxParticipants', isLessThanOrEqualTo: filterSettings.maxParticipants)
        .where('maxParticipants', isGreaterThanOrEqualTo: filterSettings.minParticipants);

      if (filterSettings.categories.isNotEmpty) {
        query = query.where('category', whereIn: filterSettings.categories);
      }

      if (filterSettings.languages.isNotEmpty) {
        query = query.where('creatorLanguages', arrayContainsAny: filterSettings.languages);
      }

      if (filterSettings.onlySameGender) {
        query = query.where('creatorGender', isEqualTo: userState.data.gender!.name);
      }

      if (!filterSettings.includePaid) {
        query = query.where('paid', isEqualTo: false);
      }

      return query;
    }

    Stream<List<DocumentSnapshot<Map<String, dynamic>>>> stream1 = geoCollectionReference.subscribeWithin(
      center: GeoFirePoint(GeoPoint(center.latitude, center.longitude)),
      radiusInKm: radiusInKm,
      field: 'location',
      geopointFrom: (data) => (data['location'] as Map<String, dynamic>)['geopoint'] as GeoPoint,
      strictMode: false,
      queryBuilder: (query) => queryBuilder(query.where('endTime', isNull: true)),
    );

    Stream<List<DocumentSnapshot<Map<String, dynamic>>>> stream2 = geoCollectionReference.subscribeWithin(
      center: GeoFirePoint(GeoPoint(center.latitude, center.longitude)),
      radiusInKm: radiusInKm,
      field: 'location',
      geopointFrom: (data) => (data['location'] as Map<String, dynamic>)['geopoint'] as GeoPoint,
      strictMode: false,
      queryBuilder: (query) => queryBuilder(query.where('endTime', isGreaterThanOrEqualTo: DateTime.now())),
    );

    Stream<List<DocumentSnapshot<Map<String, dynamic>>>> stream3 = commercialGeoCollectionReference.subscribeWithin(
      center: GeoFirePoint(GeoPoint(center.latitude, center.longitude)),
      radiusInKm: radiusInKm,
      field: 'location',
      geopointFrom: (data) => (data['location'] as Map<String, dynamic>)['geopoint'] as GeoPoint,
      strictMode: false,
      queryBuilder: (query) => query.where('endTime', isGreaterThanOrEqualTo: DateTime.now()),
    );

    return Rx.combineLatest3(stream1, stream2, stream3, (
      List<DocumentSnapshot<Map<String, dynamic>>> a,
      List<DocumentSnapshot<Map<String, dynamic>>> b,
      List<DocumentSnapshot<Map<String, dynamic>>> c,
    ) {
      final List<MiittiActivity> activities = [];
      for (var doc in a) {
        activities.add(UserCreatedActivity.fromFirestore(doc));
      }
      for (var doc in b) {
        activities.add(UserCreatedActivity.fromFirestore(doc));
      }
      for (var doc in c) {
        final commercialActivity = CommercialActivity.fromFirestore(doc);
        incrementCommercialActivityViewCounter(commercialActivity.id);
        activities.add(commercialActivity);
      }
      return activities;
    });
  }

  Future<void> incrementCommercialActivityViewCounter(String activityId) async {
  final docRef = _firestore.collection(_commercialActivitiesCollection).doc(activityId);
  await _incrementField(docRef, 'views');
}

Future<void> incrementCommercialActivityClickCounter(String activityId) async {
  final docRef = _firestore.collection(_commercialActivitiesCollection).doc(activityId);
  await _incrementField(docRef, 'clicks');
}

Future<void> incrementCommercialActivityHyperlinkClickCounter(String activityId) async {
  final docRef = _firestore.collection(_commercialActivitiesCollection).doc(activityId);
  await _incrementField(docRef, 'hyperlinkClicks');
}

Future<void> incrementAdBannerViewCounter(String id) async {
  final docRef = _firestore.collection(_adBannersCollection).doc(id);
  await _incrementField(docRef, 'views');
}

Future<void> incrementAdBannerHyperlinkClickCounter(String id) async {
  final docRef = _firestore.collection(_adBannersCollection).doc(id);
  await _incrementField(docRef, 'hyperlinkClicks');
}

Future<void> _incrementField(DocumentReference docRef, String fieldName) async {
  try {
    final docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      if (data.containsKey(fieldName)) {
        await docRef.update({fieldName: FieldValue.increment(1)});
      } else {
        await docRef.update({fieldName: 1});
      }
    }
  } catch (e) {
    debugPrint('Error incrementing field: $e');
  }
}

  // Stream<List<MiittiActivity>> streamFilteredActivities() {
  //   final filterSettings = ref.read(activitiesFilterSettingsProvider);
  //   final userState = ref.read(userStateProvider);

  //   Query query = _firestore.collection(_activitiesCollection)
    //     .where(Filter.or(
    //       Filter('endTime', isNull: true),
    //       Filter('endTime', isGreaterThanOrEqualTo: DateTime.now())))
    //     .where('creatorAge', isGreaterThanOrEqualTo: filterSettings.minAge)
    //     .where('creatorAge', isLessThanOrEqualTo: filterSettings.maxAge)
    //     .where('maxParticipants', isLessThanOrEqualTo: filterSettings.maxParticipants)
    //     .where('maxParticipants', isGreaterThanOrEqualTo: filterSettings.minParticipants);

    // if (filterSettings.categories.isNotEmpty) {
    //   query = query.where('category', whereIn: filterSettings.categories);
    // }

    // if (filterSettings.languages.isNotEmpty) {
    //   query = query.where('creatorLanguages', arrayContainsAny: filterSettings.languages);
    // }

    // if (filterSettings.onlySameGender) {
    //   query = query.where('creatorGender', isEqualTo: userState.data.gender!.name);
    // }

    // if (!filterSettings.includePaid) {
    //   query = query.where('paid', isEqualTo: false);
  //   }

  //   // TODO: Add distance filter

  //   return query.snapshots().asyncMap((querySnapshot) async {
  //     List<MiittiActivity> activities = querySnapshot.docs.map((doc) => UserCreatedActivity.fromFirestore(doc)).toList();

  //     QuerySnapshot commercialQuery = await _firestore.collection(_commercialActivitiesCollection).get();
  //     List<MiittiActivity> commercialActivities = commercialQuery.docs.map((doc) => CommercialActivity.fromFirestore(doc)).toList();

  //     List<MiittiActivity> list = List<MiittiActivity>.from(activities);
  //     list.addAll(List<MiittiActivity>.from(commercialActivities));
  //     return list;
  //   });
  // }

  Future<MiittiActivity?> fetchActivity(String activityId) async {
    try {
      final snapshot = await _firestore.collection(_commercialActivitiesCollection).doc(activityId).get();
      MiittiActivity? activity;
      if (snapshot.exists) {
        activity = CommercialActivity.fromFirestore(snapshot);
        incrementCommercialActivityViewCounter(activityId);
      } else {
        final snapshot = await _firestore.collection(_activitiesCollection).doc(activityId).get();
        activity = UserCreatedActivity.fromFirestore(snapshot);
      }
      return activity;
    } catch (e) {
      debugPrint('Error fetching activity: $e');
      return null;
    }
  }

  Future<void> deleteActivity(String activityId) async {
    try {
      await _firestore.collection(_activitiesCollection).doc(activityId).delete();
    } catch (e) {
      debugPrint('Error while removing activity: $e');
    }
  }

  Future<List<AdBannerData>> fetchAdBanners() async {
    try {
      // Banner ads could be fetched according to the activities filter settings as well
      // Add queries when needed
      QuerySnapshot querySnapshot = await _firestore.collection(_adBannersCollection).get();

      List<AdBannerData> list = querySnapshot.docs
          .map((doc) => AdBannerData.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();

      return list;

    } catch (e) {
      debugPrint("Error fetching ads $e");
      return [];
    }
  }

  Future<void> reportActivity(String activityId, List<String> reasons, String comments) async {

    try {
      DocumentReference doc = _firestore.collection('reportedActivities').doc(activityId);
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot documentSnapshot = await transaction.get(doc);

        if (documentSnapshot.exists) {
          transaction.update(doc, {
            'comments': FieldValue.arrayUnion([comments]),
            'reasons': FieldValue.arrayUnion(reasons),
            'numberOfReports': FieldValue.increment(1),
          });
        } else {
          final activity = UserCreatedActivity.fromFirestore(await _firestore.collection(_activitiesCollection).doc(activityId).get());
          transaction.set(doc, {
            'activityId': activityId,
            'comments': [comments],
            'reasons': reasons,
            'numberOfReports': 1,

            'activity': activity.toMap(),
          });
        }
      });
    } catch (e) {
      debugPrint("Reporting failed: $e");
    }
  }

  Future<void> reportUser(String reportedId, List<String> reasons, String comments) async {
    try {
      DocumentReference doc = _firestore.collection('reportedUsers').doc(reportedId);
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot documentSnapshot = await transaction.get(doc);

        if (documentSnapshot.exists) {
          transaction.update(doc, {
            'comments': FieldValue.arrayUnion([comments]),
            'reasons': FieldValue.arrayUnion(reasons),
            'numberOfReports': FieldValue.increment(1),
          });
        } else {
          final user = MiittiUser.fromFirestore(await _firestore.collection('users').doc(reportedId).get());
          transaction.set(doc, {
            'reportedId': reportedId,
            'comments': [comments],
            'reasons': reasons,
            'numberOfReports': 1,
            'user': user.toMap(),
          });
        }
      });
    } catch (e) {
      debugPrint("Reporting failed: $e");
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
      await _firestore.collection(_usersCollection).doc(uid).update(data);
    } catch (e, s) {
      debugPrint('Got an error updating user $e');
      debugPrint('$s');
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
      await _firestore.collection(_activitiesCollection).doc(activityId).update({
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
          .collection(_usersCollection)
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

  Future<List<UserCreatedActivity>> fetchReportedActivities() async {
    try {
      QuerySnapshot querySnapshot = await _getFireQuery('reportedActivities');

      List<UserCreatedActivity> list = [];

      for (QueryDocumentSnapshot report in querySnapshot.docs) {
        DocumentSnapshot doc = await _getActivityDoc(report.id);
        list.add(UserCreatedActivity.fromFirestore(doc));
      }

      return list;
    } catch (e) {
      debugPrint('Error fetching reported activities: $e');
      return [];
    }
  }

  Future<List<MiittiUser>> fetchUsers() async {
    QuerySnapshot querySnapshot = await _getFireQuery(_usersCollection);

    return querySnapshot.docs.map((doc) => MiittiUser.fromFirestore(doc)).toList();
  }

  Future<List<UserCreatedActivity>> fetchActivitiesRequestsFrom(
      String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('activities')
          .where('admin', isEqualTo: uid)
          .where('requests', arrayContains: userId)
          .get();

      List<UserCreatedActivity> activities =
          querySnapshot.docs.map((doc) => UserCreatedActivity.fromFirestore(doc)).toList();
      return activities;
    } catch (e) {
      debugPrint('Error fetching admin activities: $e');
      return [];
    }
  }

  Future<QuerySnapshot> lazyFilteredUsers(int type, int batchSize,
      [DocumentSnapshot? startAfter]) {
    Query query = _firestore.collection(_usersCollection);

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
          await _queryWhereContains(_activitiesCollection, 'participants', uid!);

      QuerySnapshot commercialSnapshot =
          await _queryWhereContains(_commercialActivitiesCollection, 'participants', uid!);

      QuerySnapshot requestSnapshot =
          await _queryWhereContains(_activitiesCollection, "requests", uid!);

      List<UserCreatedActivity> personActivities = [];
      List<CommercialActivity> commercialActivities = [];

      for (var doc in querySnapshot.docs) {
        personActivities.add(UserCreatedActivity.fromFirestore(doc));
      }

      for (var doc in commercialSnapshot.docs) {
        commercialActivities.add(CommercialActivity.fromFirestore(doc));
      }

      for (var doc in requestSnapshot.docs) {
        personActivities.add(UserCreatedActivity.fromFirestore(doc));
      }

      if (miittiUser!.invitedActivities.isNotEmpty) {
        for (String activityId in miittiUser!.invitedActivities) {
          DocumentSnapshot activitySnapshot = await _getActivityDoc(activityId);

          if (activitySnapshot.exists) {
            UserCreatedActivity activity = UserCreatedActivity.fromFirestore(activitySnapshot);
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
          await _queryWhereEquals(_activitiesCollection, 'admin', uid!);

      List<UserCreatedActivity> activities =
          querySnapshot.docs.map((doc) => UserCreatedActivity.fromFirestore(doc)).toList();

      List<Map<String, dynamic>> usersAndActivityIds = [];

      for (UserCreatedActivity activity in activities) {
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
        await uploadUserImage(ref.read(userStateProvider).uid!, imageFile)
            .then((value) {
          updatedUser.profilePicture = value;
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
    required UserCreatedActivity activityModel,
  }) async {
    showLoadingDialog(context);
    try {
      activityModel.creator = _miittiUser!.uid;
      activityModel.creatorAge = calculateAge(_miittiUser!.birthday);
      activityModel.creatorGender = _miittiUser!.gender;
      activityModel.creatorLanguages = _miittiUser!.languages;
      activityModel.id = generateCustomId();
      // activityModel.participants = [_miittiUser!.uid];
      activityModel.addParticipant(_miittiUser!.uid, _miittiUser!);
      // activityModel.participantsInfo[_miittiUser!.uid] = {
      //   'name': _miittiUser!.name,
      //   'profilePicture': _miittiUser!.profilePicture,
      // };

      await _activityDocRef(activityModel.id)
          .set(activityModel.toMap())
          .then((value) {
        showSnackBar(context, 'Miittisi on luotu onnistuneesti!', Colors.green);

        if (context.mounted) {
          context.go('/');
        }
      });
    } catch (e) {
      showSnackBar(context, e.toString(), AppStyle.red);
      if (context.mounted) {
        context.go('/');
      }
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
          ? CommercialActivity.fromFirestore(snapshot)
          : UserCreatedActivity.fromFirestore(snapshot);
      return activity.participantsInfo.keys.contains(uid);
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

  Future<List<UserCreatedActivity>> fetchAdminActivities() async {
    try {
      QuerySnapshot querySnapshot =
          await _queryWhereEquals(_activitiesCollection, 'admin', uid!);

      List<UserCreatedActivity> activities =
          querySnapshot.docs.map((doc) => UserCreatedActivity.fromFirestore(doc)).toList();

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
    return _firestore.collection(_usersCollection).doc(userId).get();
  }

  Future<DocumentSnapshot> _getActivityDoc(String activityId) {
    return _firestore.collection(_activitiesCollection).doc(activityId).get();
  }

  DocumentReference _userDocRef(String userId) {
    return _firestore.collection(_usersCollection).doc(userId);
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
      Function(UserCreatedActivity activity) isPersonal,
      Function(CommercialActivity comActivity) isCommercial) async {
    DocumentSnapshot snapshot = await _getActivityDoc(activityId);
    if (snapshot.exists) {
      UserCreatedActivity activity = UserCreatedActivity.fromFirestore(snapshot);
      isPersonal(activity);
      return activity;
    } else {
      debugPrint("is commercial");
      DocumentSnapshot comSnapshot = await _comActivityDocRef(activityId).get();
      CommercialActivity commercialActivity =
          CommercialActivity.fromFirestore(comSnapshot);
      isCommercial(commercialActivity);
      return commercialActivity;
    }
  }

  inviteUserToYourActivity(String uid, String activityUid) {}
}
