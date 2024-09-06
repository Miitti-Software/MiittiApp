import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/models/commercial_activity.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/state/service_providers.dart';

class ActivityMarker extends ConsumerWidget {
  final MiittiActivity activity;

  const ActivityMarker({required this.activity, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(remoteConfigServiceProvider);
    final activityEmoji = config.getActivityTuples().firstWhere((tuple) => tuple.item1 == activity.category).item2.item2;

    return activity is CommercialActivity
        ? Padding(
            padding: const EdgeInsets.all(13.0),
            child: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: AppStyle.violet,
                  radius: 37,
                  child: CircleAvatar(
                    // backgroundImage: NetworkImage(activity.bannerImage),
                    radius: 34,
                    onBackgroundImageError: (exception, stackTrace) => Text(
                      activityEmoji,
                      style: const TextStyle(fontSize: 34),
                    ),
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
        : Center(
          child: CircleAvatar(
            radius: 36,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                  center: const Alignment(1, -1),
                  radius: 1.0,
                ),
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondary,
                  width: 2.0,
                ),
              ),
              child: Center(
                child: Text(
                  activityEmoji,
                  style: const TextStyle(fontSize: 34),
                ),
              ),
            ),
          ),
        );
  }
}