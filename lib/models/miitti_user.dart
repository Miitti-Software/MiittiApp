import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// TODO: Rename stuff in Firebase to match this (userChoices -> qaAnswers, userStatus -> lastActive, userSchool -> associatedOrganization)
// TODO: Do a full update on Firebase to match this class

class MiittiUser {
  String email;
  String name;
  String phoneNumber;
  Timestamp birthday;
  List<String> areas;
  List<String> favoriteActivities;
  Map<String, String> qaAnswers;
  String gender;
  List<String> languages;
  List<String> profilePictures;
  String uid;
  List<String> invitedActivities;
  Timestamp lastActive;
  Map<String, String>? groups;
  String occupationalStatus;
  String? organization;
  String fcmToken;
  Timestamp registrationDate;

  MiittiUser(
      {required this.name,
      required this.email,
      required this.uid,
      required this.phoneNumber,
      required this.birthday,
      required this.areas,
      required this.favoriteActivities,
      required this.qaAnswers,
      required this.gender,
      required this.languages,
      required this.profilePictures,
      required this.invitedActivities,
      required this.lastActive,
      this.groups,
      required this.occupationalStatus,
      this.organization,
      required this.fcmToken,
      required this.registrationDate});

  factory MiittiUser.fromDoc(DocumentSnapshot snapshot) {
    return MiittiUser.fromMap(snapshot.data() as Map<String, dynamic>);
  }

  factory MiittiUser.fromMap(Map<String, dynamic> map) {
    try {
      return MiittiUser(
        name: map['userName'] ?? '',
        email: map['userEmail'] ?? '',
        uid: map['uid'] ?? '',
        phoneNumber: map['userPhoneNumber'] ?? '',
        birthday: resolveTimestamp(map['userBirthday']),
        areas: map['userArea'] ?? '',
        favoriteActivities:
            _resolveActivities(_toStringList(map['userFavoriteActivities'])),
        qaAnswers: _toStringMap(map['userChoices']),
        gender: map['userGender'] ?? '', // Updated to single File
        languages: _toStringList(map['userLanguages']),
        profilePictures: map['profilePicture'] ?? '',
        invitedActivities: _toStringList(map['invitedActivities']),
        lastActive: resolveTimestamp(map['userStatus']),
        occupationalStatus: map['occupationalStatus'] ?? '',
        organization: map['userSchool'] ?? '',
        fcmToken: map['fcmToken'] ?? '',
        registrationDate: resolveTimestamp(map['userRegistrationDate']),
      );
    } catch (e, s) {
      debugPrint('Error parsing user from map: $e | $s');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userName': name,
      'userEmail': email,
      'uid': uid,
      'userPhoneNumber': phoneNumber,
      'userBirthday': birthday,
      'userArea': areas,
      'userFavoriteActivities': favoriteActivities.toList(),
      'userChoices': qaAnswers,
      'userGender': gender,
      'userLanguages': languages.toList(),
      'profilePicture': profilePictures,
      'invitedActivities': invitedActivities.toList(),
      'lastActive': lastActive,
      'userSchool': organization,
      'fcmToken': fcmToken,
      'userRegistrationDate': registrationDate
    };
  }

  bool updateUser(Map<String, dynamic> newData) {
    try {
      name = newData['userName'] ?? name;
      email = newData['userEmail'] ?? email;
      phoneNumber = newData['userPhoneNumber'] ?? phoneNumber;
      birthday = newData['userBirthday'] ?? birthday;
      areas = newData['userArea'] ?? areas;
      lastActive = newData['lastActive'] ?? lastActive;
      organization = newData['userSchool'] ?? organization;
      fcmToken = newData['fcmToken'] ?? fcmToken;
      registrationDate =
          newData['userRegistrationDate'] ?? registrationDate;
      profilePictures = newData['profilePicture'] ?? profilePictures;
      gender = newData['userGender'] ?? gender;

      if (newData['userFavoriteActivities'] is List<dynamic>) {
        favoriteActivities = _resolveActivities(
            _toStringList(newData['userFavoriteActivities']));
      }
      if (newData['userChoices'] is Map<String, String>) {
        qaAnswers = newData['userChoices'];
      }

      if (newData['userLanguages'] is List<String>) {
        languages = newData['userLanguages'];
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
