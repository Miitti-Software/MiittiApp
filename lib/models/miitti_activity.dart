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
  bool paid;
  int maxParticipants;
  List<String> participants;

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
    required this.paid,
    required this.maxParticipants,
    required this.participants
  });
}