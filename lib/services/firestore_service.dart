import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/models/report.dart';

class FirestoreService {
  static const String _usersString = 'users';

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

  Future<DocumentSnapshot> _getUserDoc(String userId) {
    return _firestore.collection(_usersString).doc(userId).get();
  }
}
