import 'package:flutter/material.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/constants/languages.dart';
import 'package:url_launcher/url_launcher.dart';

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

  GestureDetector getWidget(BuildContext context) {
    try {
      return GestureDetector(
        onTap: () async {
          await launchUrl(Uri.parse(hyperlink));
        },
        child: Card(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          margin: const EdgeInsets.all(10.0),
          child: Container(
            width: 400,
            decoration: const BoxDecoration(
              color: AppStyle.black,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  child: Image.network(
                    image,
                    fit: BoxFit.fitWidth,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 28,
                    width: 100,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppStyle.pink.withOpacity(0.8),
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10)),
                    ),
                    child: const Text(
                      "Sponsoroitu",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Rubik',
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint("Failed getting banner: $e");
      return GestureDetector(
        onTap: () {},
        child: Container(
          height: 0,
        ),
      );
    }
  }
}
