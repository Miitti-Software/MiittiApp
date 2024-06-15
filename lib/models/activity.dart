import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/models/commercial_activity.dart';
import 'package:miitti_app/constants/constants.dart';
import 'package:miitti_app/models/miitti_activity.dart';

class Activity {
  final String name;
  final String emojiData;
  const Activity({required this.name, required this.emojiData});

  static Activity getActivity(String category) {
    if (activities.containsKey(category)) {
      return activities[category]!;
    } else {
      return activities.values.firstWhere((element) => element.name == category,
          orElse: () => activities['adventure']!);
    }
  }

  static String solveActivityId(String category) {
    debugPrint("Solving category: $category");
    if (!activities.containsKey(category)) {
      bool categoryFound = false;
      for (String key in activities.keys) {
        if (activities[key]!.name == category) {
          category = key;
          categoryFound = true;
          debugPrint("found $category");
          break;
        }
      }

      if (!categoryFound) {
        debugPrint(
            "$category not found in activities. Defaulting to adventure.");
        category = 'adventure';
      }
    } else {
      debugPrint(category);
    }
    return category;
  }

  static Widget getSymbol(MiittiActivity activity) {
    return activity is CommercialActivity
        ? Padding(
            padding: EdgeInsets.all(13.0.h),
            child: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: AppStyle.violet,
                  radius: 37.r,
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(activity.activityPhoto),
                    radius: 34.r,
                    onBackgroundImageError: (exception, stackTrace) => AssetImage(
                        'images/${solveActivityId(activity.activityCategory)}.png'),
                  ),
                ),
                const Positioned(
                  right: 0,
                  top: 0,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.circle,
                        color: AppStyle.violet,
                        size: 25,
                      ),
                      Icon(
                        Icons.verified,
                        color: AppStyle.lightPurple,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : Image.asset(
            'images/${solveActivityId(activity.activityCategory)}.png',
            height: 100.h,
            errorBuilder: (cpntext, error, stacktrace) =>
                Image.asset('images/adventure.png'),
          );
  }
}
