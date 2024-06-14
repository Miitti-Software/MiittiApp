class Report {
  String reportedId;
  List<String> reasons;
  bool isUser;

  Report(
      {required this.reportedId, required this.reasons, required this.isUser});

  factory Report.fromMap(Map<String, dynamic> map, isUser) {
    return Report(
      reportedId: map["reportedId"] ?? '',
      reasons: (map['reasons'] as List<dynamic>? ?? []).cast<String>(),
      isUser: isUser,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportedId': reportedId,
      'reasons': reasons,
    };
  }
}
