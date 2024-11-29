import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:latlong2/latlong.dart';
import 'package:miitti_app/models/ad_banner_data.dart';
import 'package:miitti_app/models/commercial_activity.dart';
import 'package:miitti_app/models/commercial_spot.dart';
import 'package:miitti_app/models/message.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/models/organization.dart';
import 'package:miitti_app/models/user_created_activity.dart';
import 'package:miitti_app/state/activities_filter_settings.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/state/users_filter_settings.dart';
import 'package:rxdart/rxdart.dart';

// A class for interfacing with the Firebase Firestore service
class FirestoreService {
  static const String _usersCollection = 'users';
  static const String _activitiesCollection = 'activities';
  static const String _commercialActivitiesCollection = 'commercialActivities';
  static const String _commercialSpotsCollection = 'commercialSpots';
  static const String _adBannersCollection = 'adBanners';
  static const String _organizationsCollection = 'organizations';
  static const String _messagesCollection = 'messages';

  final FirebaseFirestore _firestore;
  final Ref ref;
  DocumentSnapshot? _lastUserActivityDocument;
  DocumentSnapshot? _lastCommercialActivityDocument;
  DocumentSnapshot? _lastParticipatingUserActivityDocument;
  DocumentSnapshot? _lastParticipatingCommercialActivityDocument;
  DocumentSnapshot? _lastUserDocument;

  FirestoreService(this.ref) : _firestore = FirebaseFirestore.instance{
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  Future<bool> saveUserData(MiittiUser userModel) async {
    try {
      await _firestore.collection(_usersCollection).doc(userModel.uid).set(userModel.toMap());
      return true;
    } catch (e) {
      debugPrint("Error saving user data: $e");
      return false;
    }
  }

  Future<void> updateUserData(MiittiUser data) async {
    try {
      final userState = ref.read(userStateProvider);
      final userRef = _firestore.collection(_usersCollection).doc(userState.uid!);
      await userRef.update(data.toMap());
    } catch (e) {
      debugPrint('Error updating user data: $e');
    }
  }

  Future<MiittiUser?> fetchUser(String userId) async {
    try {
      final snapshot = await _firestore.collection(_usersCollection).doc(userId).get();
      if (snapshot.exists) {
        return MiittiUser.fromFirestore(snapshot);
      } else {
        debugPrint('User with ID $userId does not exist.');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
      return null;
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      final userState = ref.read(userStateProvider);

      final participantQuery = _firestore.collection(_activitiesCollection).where('participants', arrayContains: uid);
      final requestQuery = _firestore.collection(_activitiesCollection).where('requests', arrayContains: uid);
      final creatorQuery = _firestore.collection(_activitiesCollection).where('creator', isEqualTo: uid);

      final commercialParticipantQuery = _firestore.collection(_commercialActivitiesCollection).where('participants', arrayContains: uid);

      // Delete the deleted user from participants list in activities where they are a participant
      for (DocumentSnapshot doc in (await participantQuery.get()).docs) {
        final activity = UserCreatedActivity.fromFirestore(doc);
        await doc.reference.update(activity.removeParticipant(userState.data.toMiittiUser()).toMap());
      }

      // Delete the deleted user from requests list in activities where they requested to join
      for (DocumentSnapshot doc in (await requestQuery.get()).docs) {
        final activity = UserCreatedActivity.fromFirestore(doc);
        await doc.reference.update(activity.removeRequest(uid).toMap());
      }

      // Archive activities where the deleted user is the creator and where there are no participants by setting their endTime to now
      for (DocumentSnapshot doc in (await creatorQuery.get()).docs) {
        final activity = UserCreatedActivity.fromFirestore(doc);
        activity.removeParticipant(userState.data.toMiittiUser());
        activity.endTime = DateTime.now();
        await doc.reference.update(activity.toMap());
      }

      // Delete the deleted user from participants list in commercial activities where they are a participant
      for (DocumentSnapshot doc in (await commercialParticipantQuery.get()).docs) {
        final commercialActivity = CommercialActivity.fromFirestore(doc);
        await doc.reference.update(commercialActivity.removeParticipant(userState.data.toMiittiUser()).toMap());
      }

      await _firestore.collection(_usersCollection).doc(uid).delete();

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

  Future<List<MiittiActivity>> fetchParticipatingActivities({
    int pageSize = 10,
    bool fullRefresh = false,
  }) async {
    try {
      debugPrint('Fetching $pageSize participating activities');

      if (fullRefresh) {
        _lastParticipatingUserActivityDocument = null;
        _lastParticipatingCommercialActivityDocument = null;
      }

      // Load user state and filter settings
      final userState = ref.read(userStateProvider);

      // Query for user activities
      Query participatingActivitiesQuery = _firestore.collection(_activitiesCollection)
        .where('participants', arrayContains: userState.data.uid);
        
      participatingActivitiesQuery = participatingActivitiesQuery.orderBy('creationTime', descending: true);

      // Handle pagination for user activities
      if (_lastParticipatingUserActivityDocument != null) {
        participatingActivitiesQuery = participatingActivitiesQuery.startAfter([(_lastParticipatingUserActivityDocument!.data() as Map<String, dynamic>)['creationTime']]);
      }

      // Fetch user activities
      QuerySnapshot participatingActivitiesSnapshot = await participatingActivitiesQuery.limit(pageSize).get();
      List<MiittiActivity> participatingActivities = participatingActivitiesSnapshot.docs.map((doc) => UserCreatedActivity.fromFirestore(doc)).toList();

      // Update last user activity document
      if (participatingActivities.isNotEmpty) {
        _lastParticipatingUserActivityDocument = participatingActivitiesSnapshot.docs.last;
      }

      // Query for commercial activities
      Query commercialActivitiesQuery = _firestore.collection(_commercialActivitiesCollection).where('participants', arrayContains: userState.data.uid).orderBy('creationTime', descending: true);

      // Handle pagination for commercial activities
      if (_lastParticipatingCommercialActivityDocument != null) {
        commercialActivitiesQuery = commercialActivitiesQuery.startAfter([(_lastParticipatingCommercialActivityDocument!.data() as Map<String, dynamic>)['creationTime']]);
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

      // Query for requested activities
      Query requestedActivitiesQuery = _firestore.collection(_activitiesCollection)
        .where('requests', arrayContains: userState.data.uid);

      QuerySnapshot requestedActivitiesSnapshot = await requestedActivitiesQuery.get();
      List<MiittiActivity> requestedActivities = requestedActivitiesSnapshot.docs.map((doc) => UserCreatedActivity.fromFirestore(doc)).toList();

      // Combine user, commercial, and requested activities
      List<MiittiActivity> activities = List<MiittiActivity>.from(participatingActivities);
      activities.addAll(commercialActivities);
      activities.addAll(requestedActivities);

      return activities;
    } catch (e) {
      debugPrint('Error fetching activities: $e');
      return [];
    }
  }

  Stream<List<MiittiActivity>> streamActivitiesWithinRadius(LatLng center, double radiusInKm) {
    final geoCollectionReference = GeoCollectionReference(_firestore.collection(_activitiesCollection));
    final commercialGeoCollectionReference = GeoCollectionReference(_firestore.collection(_commercialActivitiesCollection));
    final filterSettings = ref.read(activitiesFilterSettingsProvider);
    final userState = ref.read(userStateProvider);

    debugPrint('Streaming activities within $radiusInKm km from $center');

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
      queryBuilder: (query) => query.where('endTime', isNull: true),
    );

    Stream<List<DocumentSnapshot<Map<String, dynamic>>>> stream4 = commercialGeoCollectionReference.subscribeWithin(
      center: GeoFirePoint(GeoPoint(center.latitude, center.longitude)),
      radiusInKm: radiusInKm,
      field: 'location',
      geopointFrom: (data) => (data['location'] as Map<String, dynamic>)['geopoint'] as GeoPoint,
      strictMode: false,
      queryBuilder: (query) => query.where('endTime', isGreaterThanOrEqualTo: DateTime.now()),
    );

    return Rx.combineLatest4(stream1, stream2, stream3, stream4, (
      List<DocumentSnapshot<Map<String, dynamic>>> s1,
      List<DocumentSnapshot<Map<String, dynamic>>> s2,
      List<DocumentSnapshot<Map<String, dynamic>>> s3,
      List<DocumentSnapshot<Map<String, dynamic>>> s4,
    ) {
      final List<MiittiActivity> activities = [];
      for (var doc in s1) {
        activities.add(UserCreatedActivity.fromFirestore(doc));
      }
      for (var doc in s2) {
        activities.add(UserCreatedActivity.fromFirestore(doc));
      }
      for (var doc in s3) {
        final commercialActivity = CommercialActivity.fromFirestore(doc);
        activities.add(commercialActivity);
      }
      for (var doc in s4) {
        final commercialActivity = CommercialActivity.fromFirestore(doc);
        activities.add(commercialActivity);
      }
      return activities;
    });
  }

  Stream<List<UserCreatedActivity>> streamUserCreatedActivities() {
    final userId = ref.read(userStateProvider).uid!;
    final now = DateTime.now();

    return _firestore.collection(_activitiesCollection)
      .where(Filter.or(
        Filter('participants', arrayContains: userId),
        Filter('requests', arrayContains: userId)
      ))
      .where(Filter.or(
        Filter('endTime', isNull: true),
        Filter('endTime', isGreaterThanOrEqualTo: now)
      ))
      .snapshots()
      .map((querySnapshot) {
        return querySnapshot.docs.map((doc) => UserCreatedActivity.fromFirestore(doc)).toList();
      });
  }

  Stream<List<CommercialActivity>> streamCommercialActivities() {
    final userId = ref.read(userStateProvider).uid!;
    final now = DateTime.now();

    return _firestore.collection(_commercialActivitiesCollection)
      .where('participants', arrayContains: userId)
      .where(Filter.or(
        Filter('endTime', isNull: true),
        Filter('endTime', isGreaterThanOrEqualTo: now)
      ))
      .snapshots()
      .map((querySnapshot) {
        return querySnapshot.docs.map((doc) => CommercialActivity.fromFirestore(doc)).toList();
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

  Future<void> incrementCommercialSpotViewCounter(String spotId) async {
    final docRef = _firestore.collection(_commercialSpotsCollection).doc(spotId);
    await _incrementField(docRef, 'views');
  }

  Future<void> incrementCommercialSpotClickCounter(String spotId) async {
    final docRef = _firestore.collection(_commercialSpotsCollection).doc(spotId);
    await _incrementField(docRef, 'clicks');
  }

  Future<void> incrementCommercialSpotActivityCounter(String spotId) async {
    final docRef = _firestore.collection(_commercialSpotsCollection).doc(spotId);
    await _incrementField(docRef, 'activitiesArranged');
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

  Future<Organization?> fetchOrganization(String organizationId) async {
    try {
      final snapshot = await _firestore.collection(_organizationsCollection).doc(organizationId).get();
      Organization? organization;
      if (snapshot.exists) {
        organization = Organization.fromFirestore(snapshot.data() as Map<String, dynamic>);
      }
      return organization;
    } catch (e) {
      debugPrint('Error fetching organization: $e');
      return null;
    }
  }

  Future<MiittiActivity?> fetchActivity(String activityId) async {
    try {
      final snapshot = await _firestore.collection(_commercialActivitiesCollection).doc(activityId).get();
      MiittiActivity? activity;
      if (snapshot.exists) {
        activity = CommercialActivity.fromFirestore(snapshot);
        incrementCommercialActivityClickCounter(activityId);
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

  Stream<MiittiActivity?> streamActivity(String activityId) {
    return _firestore
        .collection(_activitiesCollection)
        .doc(activityId)
        .snapshots()
        .asyncMap((doc) async {
          if (!doc.exists) {
            return _firestore
                .collection(_commercialActivitiesCollection)
                .doc(activityId)
                .snapshots()
                .asyncMap((commercialDoc) => 
                  commercialDoc.exists 
                    ? CommercialActivity.fromFirestore(commercialDoc) 
                    : null);
          }
          return UserCreatedActivity.fromFirestore(doc);
        })
        .switchMap((activity) => 
          activity is Stream<MiittiActivity?> 
            ? activity 
            : Stream.value(activity as MiittiActivity?));
  }

  Future<bool> deleteActivity(String activityId) async {
    try {
      await _firestore.collection(_activitiesCollection).doc(activityId).delete();
      return true;
    } catch (e) {
      debugPrint('Error while removing activity: $e');
      return false;
    }
  }

  Future<bool> updateActivityFields(Map<String, dynamic> data, String activityId, bool isCommercialActivity) async {
  try {
    final activityRef = isCommercialActivity
        ? _firestore.collection(_commercialActivitiesCollection).doc(activityId)
        : _firestore.collection(_activitiesCollection).doc(activityId);

    final activitySnapshot = await activityRef.get();
    if (!activitySnapshot.exists) {
      debugPrint('Activity does not exist.');
      return false;
    }

    // Update the activity with the new data
    await activityRef.update(data);
    return true;
  } catch (e) {
    debugPrint('Error updating activity: $e');
    return false;
  }
}

  Future<bool> updateActivityTransaction(Map<String, dynamic> data, String activityId, isCommercialActivity) async {
    try {
      final activityRef = isCommercialActivity ? _firestore.collection(_commercialActivitiesCollection).doc(activityId) : _firestore.collection(_activitiesCollection).doc(activityId);
      await _firestore.runTransaction((transaction) async {
        final activitySnapshot = await transaction.get(activityRef);
        if (!activitySnapshot.exists) {
          debugPrint('Activity does not exist.');
          return false;
        }

        // Update the activity with the new data
        transaction.update(activityRef, data);
      });
      return true;
    } catch (e) {
      debugPrint('Error updating activity: $e');
      return false;
    }
  }

  Future<bool> reportActivity(String activityId, List<String> reasons, String comments) async {

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
      return true;
    } catch (e) {
      debugPrint("Reporting failed: $e");
      return false;
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

  Future<List<MiittiUser>> fetchFilteredUsers({
    int pageSize = 10,
    bool fullRefresh = false,
  }) async {
    try {
      debugPrint('Fetching $pageSize users');

      if (fullRefresh) {
        _lastUserDocument = null;
      }

      // Load user state and filter settings
      await ref.read(usersFilterSettingsProvider.notifier).loadPreferences();
      final filterSettings = ref.read(usersFilterSettingsProvider);

      final minAgeTimestamp = Timestamp.fromMillisecondsSinceEpoch(DateTime.now().subtract(Duration(days: filterSettings.minAge * 365)).millisecondsSinceEpoch);
      final maxAgeTimestamp = Timestamp.fromMillisecondsSinceEpoch(DateTime.now().subtract(Duration(days: filterSettings.maxAge * 365)).millisecondsSinceEpoch);

      // Query for user Users
      Query usersQuery = _firestore.collection(_usersCollection)
        .where('birthday', isLessThanOrEqualTo: minAgeTimestamp)
        .where('birthday', isGreaterThanOrEqualTo: maxAgeTimestamp)
        .where('uid', isNotEqualTo: ref.read(userStateProvider).uid);

      // if (filterSettings.sameArea) {
      //   String area = userState.data.areas[0];
      //   if (userState.data.latestLocation != null) {
      //     final placemarks = await placemarkFromCoordinates(userState.data.latestLocation!.latitude, userState.data.latestLocation!.longitude);
      //     if (placemarks.isNotEmpty) {
      //       final city = placemarks.first.locality;
      //       if (city != null) {
      //         area = city;
      //       } 
      //     }
      //   }
      //   usersQuery = usersQuery.where('areas', arrayContains: area);
      // }

      if (filterSettings.interests.isNotEmpty) {
        usersQuery = usersQuery.where('favoriteActivities', arrayContainsAny: filterSettings.interests);
      }
      // if (filterSettings.languages.isNotEmpty) {
      //   usersQuery = usersQuery.where('languages', arrayContainsAny: filterSettings.languages);
      // }
      // if (filterSettings.genders.isNotEmpty) {
      //   usersQuery = usersQuery.where('gender', whereIn: filterSettings.genders.map((e) => e.name));
      // }
      usersQuery = usersQuery.orderBy('lastActive', descending: true);

      if (_lastUserDocument != null) {
        usersQuery = usersQuery.startAfter([(_lastUserDocument!.data() as Map<String, dynamic>)['lastActive']]);
      }

      QuerySnapshot usersSnapshot = await usersQuery.limit(pageSize).get();
      List<MiittiUser> users = usersSnapshot.docs.map((doc) => MiittiUser.fromFirestore(doc)).toList();

      if (users.isNotEmpty) {
        _lastUserActivityDocument = usersSnapshot.docs.last;
      }

      return users;
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return [];
    }
  }

  Future<List<CommercialSpot>> fetchCommercialSpots(String category) async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection(_commercialSpotsCollection).where('categories', arrayContains: category).get();

      List<CommercialSpot> spots = querySnapshot.docs
          .map((doc) =>
              CommercialSpot.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();

      return spots;
    } catch (e) {
      debugPrint('Error fetching commercial spots: $e');
      return [];
    }
  }

  Future<bool> createActivity(String activityId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_activitiesCollection).doc(activityId).set(data);
      return true;
    } catch (e) {
      debugPrint('Error creating activity: $e');
      return false;
    }
  }

  Stream<QuerySnapshot> getMessages(String activityId, {bool isCommercialActivity = false}) {
    DocumentReference docRef = isCommercialActivity
        ? _firestore.collection(_commercialActivitiesCollection).doc(activityId)
        : _firestore.collection(_activitiesCollection).doc(activityId);
    return docRef
        .collection(_messagesCollection)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<String?> sendMessage(String activityId, Message message, {bool isCommercialActivity = false}) async {
    try {
      DocumentReference docRef = isCommercialActivity
          ? _firestore.collection(_commercialActivitiesCollection).doc(activityId)
          : _firestore.collection(_activitiesCollection).doc(activityId);

      DocumentReference messageRef = await docRef.collection(_messagesCollection).add(message.toMap());
      return messageRef.id;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return null;
    }
  }
}
