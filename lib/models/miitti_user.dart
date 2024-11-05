import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:miitti_app/constants/genders.dart';
import 'package:miitti_app/constants/languages.dart';

class MiittiUser {
  String uid;
  String email;
  String? phoneNumber;
  String name;
  Gender gender;
  DateTime birthday;
  List<Language> languages;
  List<String> occupationalStatuses;
  List<String> organizations;
  List<String> representedOrganizations;
  List<String> areas;
  List<String> favoriteActivities;
  Map<String, String> qaAnswers;
  String profilePicture;
  DateTime registrationDate;
  DateTime lastActive;
  String fcmToken;
  bool online;

  int numOfActivitiesCreated = 0;
  int numOfActivitiesJoined = 0;
  int numOfActivitiesAttended = 0;
  List<String> peopleMet = [];
  List<String> activitiesTried = [];

  Language languageSetting;

  // TODO: Add marketing preferences here

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
      required this.registrationDate,
      required this.lastActive,
      required this.fcmToken,             // Firebase Cloud Messaging token for targeting push notifications
      required this.online,

      this.numOfActivitiesCreated = 0,
      this.numOfActivitiesJoined = 0,
      this.numOfActivitiesAttended = 0,
      this.peopleMet = const [],
      this.activitiesTried = const [],

      required this.languageSetting,
      });

  factory MiittiUser.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    try {
      final miittiUser = MiittiUser(
        uid: data['uid'],
        email: data['email'] ?? '',
        phoneNumber: data['phoneNumber'] ?? '',
        name: data['name'] ?? '',
        gender: Gender.values.firstWhere((e) => e.toString().split('.').last.toLowerCase() == data['gender'].toLowerCase()),
        birthday: data['birthday']?.toDate(),
        languages: List.from(data['languages']).map((elem) => Language.values.firstWhere((e) => e.toString().split('.').last.toLowerCase() == elem.toLowerCase())).toList(),
        occupationalStatuses: List.from(data['occupationalStatuses']),
        organizations: data['organizations'] != null ? List<String>.from(data['organizations']) : [],
        representedOrganizations: data['representedOrganizations'] != null ? List<String>.from(data['representedOrganizations']) : [],
        areas: List.from(data['areas']),
        favoriteActivities: List.from(data['favoriteActivities']),
        qaAnswers: Map.from(data['qaAnswers']),
        profilePicture: data['profilePicture'],
        registrationDate: data['registrationDate']?.toDate(),
        lastActive: data['lastActive']?.toDate(),
        fcmToken: data['fcmToken'] ?? '',
        online: data['online'] ?? false,

        numOfActivitiesCreated: data['numOfActivitiesCreated'] ?? 0,
        numOfActivitiesJoined: data['numOfActivitiesJoined'] ?? 0,
        numOfActivitiesAttended: data['numOfActivitiesAttended'] ?? 0,
        peopleMet: data['peopleMet'] != null ? List<String>.from(data['peopleMet']) : [],
        activitiesTried: data['activitiesTried'] != null ? List<String>.from(data['activitiesTried']) : [],

        languageSetting: data['languageSetting'] != null ? Language.values.firstWhere((e) => e.toString().split('.').last.toLowerCase() == data['languageSetting'].toLowerCase()) : Language.fi,
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
      'registrationDate': registrationDate,
      'lastActive': lastActive,
      'fcmToken': fcmToken,
      'online': online,

      'numOfActivitiesCreated': numOfActivitiesCreated,
      'numOfActivitiesJoined': numOfActivitiesJoined,
      'numOfActivitiesAttended': numOfActivitiesAttended,
      'peopleMet': peopleMet,
      'activitiesTried': activitiesTried,

      'languageSetting': languageSetting.code,
    };
  }

  bool updateUser(Map<String, dynamic> newData) {
    try {
      email = newData['email'] ?? email;
      phoneNumber = newData['phoneNumber'] ?? phoneNumber;
      name = newData['name'] ?? name;
      gender = newData['gender'] ?? gender;
      birthday = newData['birthday'] ?? birthday;
      languages = newData['languages'] ?? languages;
      occupationalStatuses = newData['occupationalStatuses'] ?? occupationalStatuses;
      organizations = newData['organizations'] ?? organizations;
      representedOrganizations = newData['representedOrganizations'] ?? representedOrganizations;
      areas = newData['areas'] ?? areas;
      favoriteActivities = newData['favoriteActivities'] ?? favoriteActivities;
      qaAnswers = newData['qaAnswers'] ?? qaAnswers;
      profilePicture = newData['profilePicture'] ?? profilePicture;
      lastActive = newData['lastActive'] ?? lastActive;
      fcmToken = newData['fcmToken'] ?? fcmToken;
      online = newData['online'] ?? online;
      numOfActivitiesCreated = newData['numOfActivitiesCreated'] ?? numOfActivitiesCreated;
      numOfActivitiesJoined = newData['numOfActivitiesJoined'] ?? numOfActivitiesJoined;
      numOfActivitiesAttended = newData['numOfActivitiesAttended'] ?? numOfActivitiesAttended;
      peopleMet = newData['peopleMet'] ?? peopleMet;
      activitiesTried = newData['activitiesTried'] ?? activitiesTried;
      languageSetting = newData['languageSetting'] ?? languageSetting;

      return true;
    } catch (e) {
      return false;
    }
  }
}
