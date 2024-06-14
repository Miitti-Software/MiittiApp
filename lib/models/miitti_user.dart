import 'package:cloud_firestore/cloud_firestore.dart';

class MiittiUser {
  String userEmail;
  String userName;
  String userPhoneNumber;
  String userBirthday;
  String userArea;
  Set<String> userFavoriteActivities;
  Map<String, String> userChoices;
  String userGender;
  Set<String> userLanguages;
  String profilePicture;
  String uid;
  Set<String> invitedActivities;
  String userStatus;
  String userSchool;
  String fcmToken;
  String userRegistrationDate;

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
      required this.userStatus,
      required this.userSchool,
      required this.fcmToken,
      required this.userRegistrationDate});

  factory MiittiUser.fromDoc(DocumentSnapshot snapshot) {
    return MiittiUser.fromMap(snapshot.data() as Map<String, dynamic>);
  }

  factory MiittiUser.fromMap(Map<String, dynamic> map) {
    return MiittiUser(
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      uid: map['uid'] ?? '',
      userPhoneNumber: map['userPhoneNumber'] ?? '',
      userBirthday: map['userBirthday'] ?? '',
      userArea: map['userArea'] ?? '',
      userFavoriteActivities: resolveActivities(
          (map['userFavoriteActivities'] as List<dynamic>? ?? [])
              .cast<String>()),
      userChoices: (map['userChoices'] as Map<String, dynamic>? ?? {})
          .cast<String, String>(),
      userGender: map['userGender'] ?? '', // Updated to single File
      userLanguages:
          (map['userLanguages'] as List<dynamic>? ?? []).cast<String>().toSet(),
      profilePicture: map['profilePicture'] ?? '',
      invitedActivities: (map['invitedActivities'] as List<dynamic>? ?? [])
          .cast<String>()
          .toSet(),
      userStatus: map['userStatus'] ?? '',
      userSchool: map['userSchool'] ?? '',
      fcmToken: map['fcmToken'] ?? '',
      userRegistrationDate: map['userRegistrationDate'] ?? '',
    );
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
      'userStatus': userStatus,
      'userSchool': userSchool,
      'fcmToken': fcmToken,
      'userRegistrationDate': userRegistrationDate
    };
  }

  static Set<String> resolveActivities(List<String> favorites) {
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

    return favorites.toSet();
  }
}
