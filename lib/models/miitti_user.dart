import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:miitti_app/constants/genders.dart';
import 'package:miitti_app/constants/languages.dart';

// TODO: Rename stuff in Firebase to match this (userChoices -> qaAnswers, userStatus -> lastActive, userSchool -> associatedOrganization)
// TODO: Do a full update on Firebase to match this class

class MiittiUser {
  String email;
  String name;
  String phoneNumber;
  DateTime birthday;
  List<String> areas;
  List<String> favoriteActivities;
  Map<String, String> qaAnswers;
  Gender gender;
  List<Language> languages;
  List<String> profilePictures;
  String uid;
  List<String> invitedActivities;   // activityInvites - is this the right place? Are these the activities the user has been invited to or the activities the user has invited others to?
  DateTime lastActive;
  String occupationalStatus;
  String? organization;
  String fcmToken;
  DateTime registrationDate;

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
      required this.occupationalStatus,
      this.organization,
      required this.fcmToken,             // Firebase Cloud Messaging token for targeting push notifications
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
        birthday: resolveTimestamp(map['userBirthday']).toDate(),
        areas: map['userArea'] ?? '',
        favoriteActivities:
            _resolveActivities(_toStringList(map['userFavoriteActivities'])),
        qaAnswers: _toStringMap(map['userChoices']),
        gender: map['userGender'] ?? '', // Updated to single File
        languages: _resolveLanguages(map['userLanguages']),
        profilePictures: map['profilePicture'] ?? '',
        invitedActivities: _toStringList(map['invitedActivities']),
        lastActive: resolveTimestamp(map['userStatus']).toDate(),
        occupationalStatus: map['occupationalStatus'] ?? '',
        organization: map['userSchool'] ?? '',
        fcmToken: map['fcmToken'] ?? '',
        registrationDate: resolveTimestamp(map['userRegistrationDate']).toDate(),
      );
    } catch (e, s) {
      debugPrint('Error parsing user from map: $e | $s');
      rethrow;
    }
  }

  // TODO: Remove this factory when all users have been updated to the new structure
  // Make it load based on the datatype for testing purposes
  factory MiittiUser.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    try {
      return MiittiUser(
        email: data['userEmail'] ?? '',
        name: data['userName'] ?? '',
        phoneNumber: data['userPhoneNumber'] ?? '',
        birthday: resolveTimestamp(data['userBirthday']).toDate(),
        areas: (data['userArea'] as String).split(',').map((e) => e.trim()).toList(),
        favoriteActivities: _resolveActivities(_toStringList(data['userFavoriteActivities'])),
        qaAnswers: _toStringMap(data['userChoices']) as Map<String, String>? ?? {},
        gender: data['userGender'] == 'Mies' ? Gender.male : data['userGender'] == 'Nainen' ? Gender.female : Gender.other,
        languages: _resolveLanguages(data['userLanguages']),
        profilePictures: [data['profilePicture']],
        uid: data['uid'] ?? '',
        invitedActivities: _toStringList(data['invitedActivities']),
        lastActive: resolveTimestamp(data['userStatus']).toDate(),
        occupationalStatus: data['occupationalStatus'] ?? '',
        organization: data['userSchool'] ?? '',
        fcmToken: data['fcmToken'] ?? '',
        registrationDate: resolveTimestamp(data['userRegistrationDate']).toDate(),
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
      'userGender': gender.name,
      'userLanguages': languages.toList().map((e) => e.code),
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
      "Liikkumaan": "exercise",
      "Ulkoilemaan": "outdoors",
      "Seikkailemaan": "adventure",
      "Pallopeleille": "ball-games",
      "Mailapeleille": "racket-sports",
      "Salille": "gym",
      "Syömään": "eating",
      "Kahville": "coffee",
      "Hengailemaan": "hangout",
      "Konserttiin": "concert",
      "Näyttelyyn": "museum",
      "Teatteriin": "theater",
      "Leffaan": "cinema",
      "Lasilliselle": "drinks",
      "Lautapelit": "board-games",
      "Opiskelemaan": "studying",
      "Matkustamaan": "traveling",
      "Valokuvaamaan": "photography",
      "Bilettämään": "party",
      "Approilemaan": "bar-crawl",
      "Festareille": "festival",
      "Saunomaan": "sauna",
      "Laskettelemaan": "winter-sports",
      "Luistelemaan": "ice-skating",
      "Roadtripille": "roadtrip",
      "Pyöräilemään": "cycling",
      "Pelaamaan": "gaming",
      "Skeittaamaan": "skateboarding",
      "Retkeilemään": "hiking",
      "Leikkitreffeille": "playdate",
      "Kirjakerhoon": "bookclub",
      "Uimaan": "swimming",
      "Kiipeilemään": "climbing",
      "Keilaamaan": "bowling",
      "Golfaamaan": "golf",
      "Sightseeing": "sightseeing",
      "Askartelemaan": "crafts",
      "Jameille": "jamming",
      "Shoppailemaan": "shopping",
      "Katuesitys": "street-performance",
      "Standup": "stand-up",
      "Parkour": "parkour",

      "Jalkapallo": "ball-games",
      "Golf": "golf",
      "Festarille": "festival",
      "Sulkapallo": "racket-sports",
      "Hengailla": "hangout",
      "Bailaamaan": "party",
      "Museoon": "museum",
      "Opiskelu": "study",
      "Taidenäyttelyyn": "museum",
      "Koripallo": "ball-games",
    };

    for (int i = 0; i < favorites.length; i++) {
      if (changed.keys.contains(favorites[i])) {
        favorites[i] = changed[favorites[i]]!;
      }
    }

    return favorites;
  }

  static List<Language> _resolveLanguages(List<String> languages) {
    Map<String, Language> changed = {
      "🇫🇮": Language.fi,
      "🇸🇪": Language.sv,
      "🇬🇧": Language.en,
    };

    List<Language> output = [];

    for (int i = 0; i < languages.length; i++) {
      if (changed.keys.contains(languages[i])) {
        output[i] = changed[languages[i]]!;
      }
    }

    return output;
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
