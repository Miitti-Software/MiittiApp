import 'package:flutter/material.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class AdBanner {
  String uid;
  String image;
  String link;
  Set<String> targetActivities;
  int targetMinAge;
  int targetMaxAge;
  bool targetMen;
  bool targetWomen;
  bool targetNonBinary;

  AdBanner({
    required this.image,
    required this.link,
    required this.targetActivities,
    required this.targetMinAge,
    required this.targetMaxAge,
    required this.targetMen,
    required this.targetWomen,
    required this.targetNonBinary,
    required this.uid,
  });

  factory AdBanner.fromMap(Map<String, dynamic> map) {
    return AdBanner(
      uid: map['uid'] ?? '',
      image: map['image'] ?? '',
      link: map['link'] ?? '',
      targetActivities: (map['targetActivities'] as List<dynamic>? ?? [])
          .cast<String>()
          .toSet(),
      targetMinAge: map['targetMinAge'] ?? 18,
      targetMaxAge: map['targetMaxAge'] ?? 80,
      targetMen: map['targetMen'] ?? true,
      targetWomen: map['targetWomen'] ?? true,
      targetNonBinary: map['targetNonBinary'] ?? true,
    );
  }

  int targetWeight(MiittiUser user) {
    try {
      int weight = 0;
      int age = calculateAge(user.birthday);
      if (age < targetMinAge || age > targetMaxAge) weight += 1;

      for (var activity in targetActivities) {
        if (user.favoriteActivities.contains(activity)) weight += 1;
      }

      if (user.gender == "Mies" && !targetMen) {
        weight -= 1;
      } else if (user.gender == "Nainen" && !targetWomen) {
        weight -= 1;
      } else if (user.gender == "Ei-binäärinen" && !targetNonBinary) {
        weight -= 1;
      }

      return weight;
    } catch (e) {
      debugPrint("Error targeting ad: $e");
      return 0;
    }
  }

  /*bool targetCommon(MiittiUser user, MiittiUser another) {
    return targetUser(user) && targetUser(another);
  }*/

  static List<AdBanner> sortBanners(List<AdBanner> banners, MiittiUser? user) {
    banners.shuffle();
    if (user != null) {
      banners
          .sort((a, b) => b.targetWeight(user).compareTo(a.targetWeight(user)));
    }

    return banners;
  }

  GestureDetector getWidget(BuildContext context) {
    try {
      return GestureDetector(
        onTap: () async {
          await launchUrl(Uri.parse(link));
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
