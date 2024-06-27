import 'package:cloud_firestore/cloud_firestore.dart';

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
    return MiittiUser(
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      uid: map['uid'] ?? '',
      userPhoneNumber: map['userPhoneNumber'] ?? '',
      userBirthday: resolveSimpleDate(map['userBirthday']),
      userArea: map['userArea'] ?? '',
      userFavoriteActivities: _resolveActivities(
          (map['userFavoriteActivities'] as List<dynamic>? ?? [])
              .cast<String>()),
      userChoices: (map['userChoices'] as Map<String, dynamic>? ?? {})
          .cast<String, String>(),
      userGender: map['userGender'] ?? '', // Updated to single File
      userLanguages: (map['userLanguages'] as List<dynamic>? ?? []).cast<String>(),
      profilePicture: map['profilePicture'] ?? '',
      invitedActivities: (map['invitedActivities'] as List<dynamic>? ?? []).cast<String>(),
      lastActive: resolveTimestamp(map.containsKey('lastActive') ? map['lastActive'] : map['userStatus']), // lastActive was formerly called userStatus and hence the field might differ for new and old users
      userSchool: map['userSchool'] ?? '',
      fcmToken: map['fcmToken'] ?? '',
      userRegistrationDate: resolveSimpleDate(map['userRegistrationDate']),
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
        userFavoriteActivities =
            _resolveActivities(newData['userFavoriteActivities'])
                .cast<String>();
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

  static Timestamp resolveSimpleDate(dynamic time) {
    if (time == null) {
      return _defaultTime;
    }
    try {
      return time as Timestamp;
    } catch (e) {
      final simpleDate = (time as String).split('/');
      final day = int.parse(simpleDate[0]);
      final month = int.parse(simpleDate[1]);
      final year = int.parse(simpleDate[2]);
      return Timestamp.fromDate(DateTime(year, month, day));
    }
  }

  static Timestamp resolveTimestamp(dynamic time) {
    if (time == null) {
      return _defaultTime;
    }
    try {
      return time as Timestamp;
    } catch (e) {
      return Timestamp.fromDate(DateTime.parse(time as String));
    }
  }

  static final Timestamp _defaultTime = Timestamp.fromDate(DateTime(2000));
}
