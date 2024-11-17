import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/models/commercial_activity.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/services/analytics_service.dart';
import 'package:miitti_app/services/cache_manager_service.dart';
import 'package:miitti_app/state/ads_state.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:visibility_detector/visibility_detector.dart';

class CommercialActivityMarker extends ConsumerWidget {
  final MiittiActivity activity;
  final double size;

  const CommercialActivityMarker({required this.activity, this.size = 34, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(remoteConfigServiceProvider);
    const activityEmoji = '💎';

    return VisibilityDetector(
      key: Key(activity.id),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction > 0.5) {
          if (!adViewSessionManager.hasViewed(activity.id)) {
            ref.read(analyticsServiceProvider).logCommercialActivityView(activity as CommercialActivity);
            ref.read(adsStateProvider.notifier).incrementCommercialActivityViewCount(activity.id);
            adViewSessionManager.markAsViewed(activity.id);
          }
        }
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(120),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              radius: size,
              child: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(
                  (activity as CommercialActivity).bannerImage,
                  cacheManager: ProfilePicturesCacheManager(),
                ),
                radius: size - 3,
                onBackgroundImageError: (exception, stackTrace) => Text(
                  activityEmoji,
                  style: TextStyle(fontSize: size - 3),
                ),
              ),
            ),
          ),
          // const Positioned(
          //   right: 0,
          //   top: 0,
          //   child: Stack(
          //     alignment: Alignment.center,
          //     children: [
          //       Icon(
          //         Icons.circle,
          //         color: AppStyle.violet,
          //         size: 25,
          //       ),
          //       Icon(
          //         Icons.verified,
          //         color: AppStyle.lightPurple,
          //         size: 20,
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}