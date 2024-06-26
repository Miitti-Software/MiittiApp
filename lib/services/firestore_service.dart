import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/functions/filter_settings.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:miitti_app/models/commercial_activity.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/models/person_activity.dart';
import 'package:miitti_app/models/report.dart';

import '../screens/activity_details_page.dart';

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

  void reset() {
    _miittiUser = null;
  }

  Future<bool> checkExistingUser(String userId) async {
    return _wait(() => _tryGetUser(userId, exists: (miittiUser) {
          _miittiUser = miittiUser;
        }));
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

  Future<MiittiUser?> getUser(String userId) async {
    MiittiUser? user;
    _wait(
      () => _tryGetUser(userId, exists: (miittiUser) {
        user = miittiUser;
      }),
    );
    return user;
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
      return result.docs.map((doc) => MiittiUser.fromDoc(doc)).toList();
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
            activity.adminGender != miittiUser!.userGender) {
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

  Future<void> removeActivity(String activityId) async {
    try {
      await _firestore.collection(_activitiesString).doc(activityId).delete();
    } catch (e) {
      debugPrint('Error while removing activity: $e');
    }
  }

  //PRIVATE UTILS

  Future<bool> _tryGetUser(String userId,
      {Function(MiittiUser user)? exists, Function? notFound}) async {
    DocumentSnapshot snapshot = await _getUserDoc(userId);
    if (snapshot.exists) {
      if (exists != null) {
        await exists(MiittiUser.fromDoc(snapshot));
      }
      return true;
    } else {
      if (notFound != null) {
        await notFound();
      }
      return false;
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

  DocumentReference _comActivityDocRef(String activityId) {
    return _firestore.collection('commercialActivities').doc(activityId);
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
}
