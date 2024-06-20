import 'package:cloud_firestore/cloud_firestore.dart';

class MiittiUser {
  String userEmail;
  String userName;
  String userPhoneNumber;
  Timestamp userBirthday;
  String userArea;
  Set<String> userFavoriteActivities;
  Map<String, String> userChoices;
  String userGender;
  Set<String> userLanguages;
  String profilePicture;
  String uid;
  Set<String> invitedActivities;
  Timestamp userStatus;
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
      userBirthday: resolveTimestamp(map['userBirthday']),
      userArea: map['userArea'] ?? '',
      userFavoriteActivities: _resolveActivities(
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

  void updateUser(Map<String, dynamic> newData) {
    userName = newData['userName'] ?? userName;
    userEmail = newData['userEmail'] ?? userEmail;
    userPhoneNumber = newData['userPhoneNumber'] ?? userPhoneNumber;
    userBirthday = newData['userBirthday'] ?? userBirthday;
    userArea = newData['userArea'] ?? userArea;
    userFavoriteActivities = _resolveActivities(
        (newData['userFavoriteActivities'] as List<dynamic>? ?? [])
            .cast<String>());
    userChoices = (newData['userChoices'] as Map<String, dynamic>? ?? {})
        .cast<String, String>();
    userGender = newData['userGender'] ?? userGender;
    userLanguages = (newData['userLanguages'] as List<dynamic>? ?? [])
        .cast<String>()
        .toSet();
    profilePicture = newData['profilePicture'] ?? profilePicture;
    invitedActivities = (newData['invitedActivities'] as List<dynamic>? ?? [])
        .cast<String>()
        .toSet();
    userStatus = newData['userStatus'] ?? userStatus;
    userSchool = newData['userSchool'] ?? userSchool;
    fcmToken = newData['fcmToken'] ?? fcmToken;
    userRegistrationDate =
        newData['userRegistrationDate'] ?? userRegistrationDate;
  }

  static Set<String> _resolveActivities(List<String> favorites) {
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

  static Timestamp resolveTimestamp(dynamic time) {
    if (time == null) {
      return _defaultTime;
    }
    try {
      return time as Timestamp;
    } catch (e) {
      final birthDate = (time as String).split('/');
      final day = int.parse(birthDate[0]);
      final month = int.parse(birthDate[1]);
      final year = int.parse(birthDate[2]);
      return Timestamp.fromDate(DateTime(year, month, day));
    }
  }

  static final Timestamp _defaultTime = Timestamp.fromDate(DateTime(2000));
}
