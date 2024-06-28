import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:miitti_app/functions/dynamic_extensions.dart';

class MiittiUser {
  String userEmail;
  String userName;
  String userPhoneNumber;
  Timestamp userBirthday;
  String userArea;
  List<String> userFavoriteActivities;
  Map<String, String> userChoices;
  String userGender;
  List<String> userLanguages;
  String profilePicture;
  String uid;
  List<String> invitedActivities;
  Timestamp lastActive;
  String userSchool;
  String fcmToken;
  Timestamp userRegistrationDate;

  MiittiUser(
      {required this.userName,
      required this.userEmail,
      required this.uid,
      required this.userPhoneNumber,
      required this.userBirthday,
      required this.userArea,
      required this.userFavoriteActivities,
      required this.userChoices,
      required this.userGender,
      required this.userLanguages,
      required this.profilePicture,
      required this.invitedActivities,
      required this.lastActive,
      required this.userSchool,
      required this.fcmToken,
      required this.userRegistrationDate});

  factory MiittiUser.fromDoc(DocumentSnapshot snapshot) {
    return MiittiUser.fromMap(snapshot.data() as Map<String, dynamic>);
  }

  factory MiittiUser.fromMap(Map<String, dynamic> map) {
    try {
      return MiittiUser(
        userName: map['userName'] ?? '',
        userEmail: map['userEmail'] ?? '',
        uid: map['uid'] ?? '',
        userPhoneNumber: map['userPhoneNumber'] ?? '',
        userBirthday: resolveTimestamp(map['userBirthday']),
        userArea: map['userArea'] ?? '',
        userFavoriteActivities:
            _resolveActivities(_toStringList(map['userFavoriteActivities'])),
        userChoices: _toStringMap(map['userChoices']),
        userGender: map['userGender'] ?? '', // Updated to single File
        userLanguages: _toStringList(map['userLanguages']),
        profilePicture: map['profilePicture'] ?? '',
        invitedActivities: _toStringList(map['invitedActivities']),
        lastActive: resolveTimestamp(map['userStatus']),
        userSchool: map['userSchool'] ?? '',
        fcmToken: map['fcmToken'] ?? '',
        userRegistrationDate: resolveTimestamp(map['userRegistrationDate']),
      );
    } catch (e, s) {
      debugPrint('Error parsing user from map: $e | $s');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'userEmail': userEmail,
      'uid': uid,
      'userPhoneNumber': userPhoneNumber,
      'userBirthday': userBirthday,
      'userArea': userArea,
      'userFavoriteActivities': userFavoriteActivities.toList(),
      'userChoices': userChoices,
      'userGender': userGender,
      'userLanguages': userLanguages.toList(),
      'profilePicture': profilePicture,
      'invitedActivities': invitedActivities.toList(),
      'lastActive': lastActive,
      'userSchool': userSchool,
      'fcmToken': fcmToken,
      'userRegistrationDate': userRegistrationDate
    };
  }

  bool updateUser(Map<String, dynamic> newData) {
    try {
      userName = newData['userName'] ?? userName;
      userEmail = newData['userEmail'] ?? userEmail;
      userPhoneNumber = newData['userPhoneNumber'] ?? userPhoneNumber;
      userBirthday = newData['userBirthday'] ?? userBirthday;
      userArea = newData['userArea'] ?? userArea;
      lastActive = newData['lastActive'] ?? lastActive;
      userSchool = newData['userSchool'] ?? userSchool;
      fcmToken = newData['fcmToken'] ?? fcmToken;
      userRegistrationDate =
          newData['userRegistrationDate'] ?? userRegistrationDate;
      profilePicture = newData['profilePicture'] ?? profilePicture;
      userGender = newData['userGender'] ?? userGender;

      if (newData['userFavoriteActivities'] is List<dynamic>) {
        userFavoriteActivities = _resolveActivities(
            _toStringList(newData['userFavoriteActivities']));
      }
      if (newData['userChoices'] is Map<String, String>) {
        userChoices = newData['userChoices'];
      }

      if (newData['userLanguages'] is List<String>) {
        userLanguages = newData['userLanguages'];
      }

      if (newData['invitedActivities'] is List<String>) {
        invitedActivities = newData['invitedActivities'];
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static List<String> _resolveActivities(List<String> favorites) {
    Map<String, String> changed = {
      "Jalkapallo": "Pallopeleille",
      "Golf": "Golfaamaan",
      "Festarille": "Festareille",
      "Sulkapallo": "Mailapeleille",
      "Hengailla": "Hengailemaan",
      "Bailaamaan": "Bilettämään",
      "Museoon": "Näyttelyyn",
      "Opiskelu": "Opiskelemaan",
      "Taidenäyttelyyn": "Näyttelyyn",
      "Koripallo": "Pallopeleille",
    };

    for (int i = 0; i < favorites.length; i++) {
      if (changed.keys.contains(favorites[i])) {
        favorites[i] = changed[favorites[i]]!;
      }
    }

    return favorites;
  }

  static List<String> _toStringList(dynamic list) {
    if (list is List<dynamic>) {
      return list.cast<String>();
    }
    return [];
  }

  static Map<String, String> _toStringMap(dynamic map) {
    if (map is Map<String, dynamic>) {
      return map.cast<String, String>();
    }
    return {};
  }

  static Timestamp resolveTimestamp(dynamic time) {
    if (time == null) {
      return _defaultTime;
    }
    try {
      return time as Timestamp;
    } catch (e) {
      try {
        final birthDate = (time as String).split('/');
        final day = int.parse(birthDate[0]);
        final month = int.parse(birthDate[1]);
        final year = int.parse(birthDate[2]);
        return Timestamp.fromDate(DateTime(year, month, day));
      } catch (e) {
        try {
          return Timestamp.fromDate(DateTime.parse(time));
        } catch (e) {
          return _defaultTime;
        }
      }
    }
  }

  static final Timestamp _defaultTime = Timestamp.fromDate(DateTime(2000));
}
