import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/state/service_providers.dart';

class ActivityMarker extends ConsumerWidget {
  final MiittiActivity activity;
  final double size;

  const ActivityMarker({required this.activity, this.size = 34, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(remoteConfigServiceProvider);
    final activityEmoji = config.getActivityTuple(activity.category).item2;

    return Center(
          child: CircleAvatar(
            radius: 36,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                  center: Alignment.topCenter,
                  radius: 1.0,
                ),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2.0,
                ),
              ),
              child: Center(
                child: Text(
                  activityEmoji,
                  style: TextStyle(fontSize: size),
                ),
              ),
            ),
          ),
        );
  }
}