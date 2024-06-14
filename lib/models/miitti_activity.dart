abstract class MiittiActivity {
  String activityTitle;
  String activityDescription;
  String activityCategory;
  String admin;
  String activityUid;

  double activityLong;
  double activityLati;
  String activityAdress;
  bool isMoneyRequired;

  int personLimit;

  Set<String> participants;

  MiittiActivity({
    required this.activityTitle,
    required this.activityDescription,
    required this.activityCategory,
    required this.admin,
    required this.activityUid,
    required this.activityLong,
    required this.activityLati,
    required this.activityAdress,
    required this.isMoneyRequired,
    required this.personLimit,
    required this.participants,
  });

  String get timeString;
}
