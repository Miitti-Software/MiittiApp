import 'package:miitti_app/constants/languages.dart';

class AdBannerData {
  String id;
  String image;
  String hyperlink;
  int clicks;
  int views;
  List<String>? targetActivities;
  List<String>? targetLocations;
  List<String>? targetOccupationalStatuses;
  List<Language>? targetLanguages;
  int? targetMinAge;
  int? targetMaxAge;
  bool? targetMen;
  bool? targetWomen;

  AdBannerData({
    required this.id,
    required this.image,
    required this.hyperlink,
    required this.clicks,
    required this.views,
    this.targetActivities,
    this.targetLocations,
    this.targetOccupationalStatuses,
    this.targetLanguages,
    this.targetMinAge,
    this.targetMaxAge,
    this.targetMen,
    this.targetWomen,
  });

  factory AdBannerData.fromFirestore(Map<String, dynamic> data) {
    return AdBannerData(
      id: data['id'] ?? '',
      image: data['image'] ?? '',
      hyperlink: data['hyperlink'] ?? '',
      clicks: data['clicks'] ?? 0,
      views: data['views'] ?? 0,
      targetActivities: data['targetActivities'] ?? [],
      targetLocations: data['targetLocations'] ?? [],
      targetOccupationalStatuses: data['targetOccupationalStatuses'] ?? [],
      targetLanguages: data['targetLanguages'] != null ? List.from(data['targetLanguages']).map((elem) => Language.values.firstWhere((e) => e.toString().split('.').last.toLowerCase() == elem.toLowerCase())).toList() : [],
      targetMinAge: data['targetMinAge'] ?? 18,
      targetMaxAge: data['targetMaxAge'] ?? 100,
      targetMen: data['targetMen'] ?? true,
      targetWomen: data['targetWomen'] ?? true,
    );
  }
}