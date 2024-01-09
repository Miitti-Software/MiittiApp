import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:miitti_app/constants/miitti_activity.dart';
import 'package:miitti_app/utils/utils.dart';

class CommercialActivity extends MiittiActivity {
  Timestamp startTime;
  Timestamp endTime;
  String linkTitle;
  String hyperlink;

  @override
  String get timeString {
    return "${timestampToString(startTime)} - ${timestampToString(endTime)}";
  }

  CommercialActivity(
      {required super.activityTitle,
      required super.activityDescription,
      required super.activityCategory,
      required super.admin,
      required super.activityUid,
      required super.activityLong,
      required super.activityLati,
      required super.activityAdress,
      required this.startTime,
      required this.endTime,
      required super.isMoneyRequired,
      required super.personLimit,
      required super.participants,
      required this.hyperlink,
      required this.linkTitle});

  static CommercialActivity fromMap(Map<String, dynamic> map) {
    return CommercialActivity(
        activityTitle: map['activityTitle'],
        activityDescription: map['activityDescription'],
        activityCategory: map['activityCategory'],
        admin: map['admin'],
        activityUid: map['activityUid'],
        activityLong: map['activityLong'],
        activityLati: map['activityLati'],
        activityAdress: map['activityAdress'],
        startTime: map['startTime'] ?? Timestamp.now(),
        endTime: map['endTime'] ?? Timestamp.now(),
        isMoneyRequired: map['isMoneyRequired'],
        personLimit: map['personLimit'],
        participants: Set<String>.from(map['participants'] ?? []),
        hyperlink: map['hyperLink'],
        linkTitle: map['linkTitle']);
  }
}
