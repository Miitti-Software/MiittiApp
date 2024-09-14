import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:miitti_app/constants/genders.dart';
import 'package:miitti_app/constants/languages.dart';

// TODO: Rename stuff in Firebase to match this (userChoices -> qaAnswers, userStatus -> lastActive, userSchool -> associatedOrganization)
// TODO: Do a full update on Firebase to match this class

class MiittiUser {
  String uid;
  String email;
  String? phoneNumber;
  String name;
  Gender gender;
  DateTime birthday;
  List<Language> languages;
  List<String> occupationalStatuses;  // make into list
  List<String> organizations;
  List<String> representedOrganizations;
  List<String> areas;
  List<String> favoriteActivities;
  Map<String, String> qaAnswers;
  String profilePicture;
  List<String> invitedActivities;   // activityInvites - is this the right place? Are these the activities the user has been invited to or the activities the user has invited others to?
  DateTime registrationDate;
  DateTime lastActive;
  String fcmToken;

  // Add marketing preferences here

  MiittiUser(
      {required this.uid,
      required this.email,
      this.phoneNumber,
      required this.name,
      required this.gender,
      required this.birthday,
      required this.languages,
      required this.occupationalStatuses,
      required this.organizations,
      required this.representedOrganizations,
      required this.areas,
      required this.favoriteActivities,
      required this.qaAnswers,
      required this.profilePicture,
      required this.invitedActivities,
      required this.registrationDate,
      required this.lastActive,
      required this.fcmToken,             // Firebase Cloud Messaging token for targeting push notifications
      });

  // TODO: Remove this factory in favor of a more elegant one when all users have been updated to the new structure
  factory MiittiUser.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    try {
      final miittiUser = MiittiUser(
        uid: data['uid'],
        email: data['email'] ?? data['userEmail'] ?? '',
        phoneNumber: data['phoneNumber'] ?? data['userPhoneNumber'] ?? '',
        name: data['name'] ?? data['userName'] ?? '',
        gender: data['gender'] != null ? Gender.values.firstWhere((e) => e.toString().split('.').last.toLowerCase() == data['gender'].toLowerCase()) : (data['userGender'] == 'Mies' ? Gender.male : data['userGender'] == 'Nainen' ? Gender.female : Gender.other),
        birthday: resolveTimestamp(data['birthday'] ?? data['userBirthday']).toDate(),
        languages: data['languages'] != null ? List.from(data['languages']).map((elem) => Language.values.firstWhere((e) => e.toString().split('.').last.toLowerCase() == elem.toLowerCase())).toList() : _resolveLanguages(List.from(data['userLanguages'])),
        occupationalStatuses: data['occupationalStatuses'] != null ? List.from(data['occupationalStatuses']) : (['Opiskelija', 'Työelämässä', 'Yrittäjä', 'Etsimässä itseään'].contains(data['userSchool']) ? [{'Opiskelija': 'student', 'Työelämässä': 'working', 'Yrittäjä': 'entrepreneur', 'Etsimässä itseään': 'other-occupational-status'}[data['userSchool']]!] : []),    // TODO: What to do with empty occupational statuses?
        organizations: data['organization'] != null ? List<String>.from(data['organization']) : [],
        representedOrganizations: data['representedOrganizations'] != null ? List<String>.from(data['representedOrganizations']) : [],
        areas: data['areas'] != null ? _toStringList(data['areas']) : (data['userArea'] as String).split(',').map((e) => e.trim()).toList(),
        favoriteActivities: data['favoriteActivities'] != null ? List.from(data['favoriteActivities']) : _resolveActivities(_toStringList(data['userFavoriteActivities'])),
        qaAnswers: Map.from(data['qaAnswers'] ?? data['userChoices']),
        profilePicture: data['profilePicture'],
        invitedActivities: data['invitedActivities'] != null ? List.from(data['invitedActivities']) : [],
        registrationDate: data['registrationDate']?.toDate() ?? resolveTimestamp(data['userRegistrationDate']).toDate(),
        lastActive: data['lastActive']?.toDate() ?? resolveTimestamp(data['userStatus']).toDate(),
        fcmToken: data['fcmToken'] ?? '',
      );
      
      return miittiUser;
    } catch (e, s) {
      debugPrint('Error parsing user from map: $e | $s');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'phoneNumber': phoneNumber,
      'name': name,
      'gender': gender.name,
      'birthday': birthday,
      'languages': languages.map((e) => e.code),
      'occupationalStatuses': occupationalStatuses,
      'organizations': organizations,
      'representedOrganizations': representedOrganizations,
      'areas': areas,
      'favoriteActivities': favoriteActivities,
      'qaAnswers': qaAnswers,
      'profilePicture': profilePicture,
      'invitedActivities': invitedActivities,
      'registrationDate': registrationDate,
      'lastActive': lastActive,
      'fcmToken': fcmToken,
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
      organizations = newData['userSchool'] ?? organizations;
      fcmToken = newData['fcmToken'] ?? fcmToken;
      registrationDate =
          newData['userRegistrationDate'] ?? registrationDate;
      profilePicture = newData['profilePicture'] ?? profilePicture;
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
      "Suomi": Language.fi,
      "Englanti": Language.en,
      "Ruotsi": Language.sv,
      "Viro": Language.et,
      "Venäjä": Language.ru,
      "Arabia": Language.ar,
      "Saksa": Language.de,
      "Ranska": Language.fr,
      "Espanja": Language.es,
      "Kiina": Language.zh,
    };

    List<Language> output = [];

    for (int i = 0; i < languages.length; i++) {
      if (changed.keys.contains(languages[i])) {
        output.add(changed[languages[i]]!);
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
