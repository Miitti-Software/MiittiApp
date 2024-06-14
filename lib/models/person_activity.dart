import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/functions/utils.dart';

class PersonActivity extends MiittiActivity {
  Timestamp activityTime;
  bool timeDecidedLater;

  Set<String> requests;

  String adminGender;
  int adminAge;

  @override
  String get timeString {
    return timeDecidedLater
        ? "Sovitaan myöhemmin"
        : timestampToString(activityTime);
  }

  PersonActivity({
    required super.activityTitle,
    required super.activityDescription,
    required super.activityCategory,
    required super.admin,
    required super.activityUid,
    required super.activityLong,
    required super.activityLati,
    required super.activityAdress,
    required this.activityTime,
    required super.isMoneyRequired,
    required super.personLimit,
    required super.participants,
    required this.requests,
    required this.adminGender,
    required this.adminAge,
    required this.timeDecidedLater,
  });

  Map<String, dynamic> toMap() {
    return {
      'activityTitle': activityTitle,
      'activityDescription': activityDescription,
      'activityCategory': activityCategory,
      'admin': admin,
      'activityUid': activityUid,
      'activityLong': activityLong,
      'activityLati': activityLati,
      'activityAdress': activityAdress,
      'activityTime': activityTime,
      'isMoneyRequired': isMoneyRequired,
      'personLimit': personLimit,
      'participants': participants.toList(),
      'requests': requests.toList(),
      'adminGender': adminGender,
      'adminAge': adminAge,
      'decidedLater': timeDecidedLater,
    };
  }

  static PersonActivity fromDoc(DocumentSnapshot snapshot) {
    return fromMap(snapshot.data() as Map<String, dynamic>);
  }

  static PersonActivity fromMap(Map<String, dynamic> map) {
    return PersonActivity(
      activityTitle: map['activityTitle'],
      activityDescription: map['activityDescription'],
      activityCategory: map['activityCategory'],
      admin: map['admin'],
      activityUid: map['activityUid'],
      activityLong: map['activityLong'],
      activityLati: map['activityLati'],
      activityAdress: map['activityAdress'],
      activityTime: map['activityTime'],
      isMoneyRequired: map['isMoneyRequired'],
      personLimit: map['personLimit'],
      participants: Set<String>.from(map['participants']),
      requests: Set<String>.from(map['requests']),
      adminGender: map['adminGender'] ?? "False",
      adminAge: map['adminAge'],
      timeDecidedLater: map['decidedLater'] ?? true,
    );
  }
}
