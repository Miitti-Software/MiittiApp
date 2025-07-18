import 'package:miitti_app/models/miitti_user.dart';

abstract class MiittiActivity {
  String id;
  String title;
  String description;
  String category;
  double longitude;
  double latitude;
  String address;
  String creator;
  DateTime creationTime;
  DateTime? startTime;
  DateTime? endTime;
  DateTime latestActivity;
  DateTime? latestMessage;
  DateTime? latestRequest;
  DateTime? latestJoin;
  bool paid;
  int maxParticipants;
  List<String> participants;
  Map<String, Map<String, dynamic>> participantsInfo;

  MiittiActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.longitude,
    required this.latitude,
    required this.address,
    required this.creator,
    required this.creationTime,
    required this.startTime,
    required this.endTime,
    required this.latestActivity,
    required this.latestMessage,
    required this.latestJoin,
    required this.paid,
    required this.maxParticipants,
    required this.participants,
    required this.participantsInfo
  });

  Map<String, dynamic> toMap();
  MiittiActivity addParticipant(MiittiUser user);
  MiittiActivity removeParticipant(MiittiUser user);
  MiittiActivity addMessageNotification();
  MiittiActivity markSeen(String userId);
  MiittiActivity markMessageRead(String userId, String messageId);
  MiittiActivity updateStartTime(DateTime? startTime);
  MiittiActivity updateEndTime(DateTime? endTime);
}