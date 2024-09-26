import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/services/analytics_service.dart';
import 'package:miitti_app/state/ads_state.dart';
import 'package:miitti_app/widgets/other_widgets.dart';
import 'package:miitti_app/models/commercial_spot.dart';
import 'package:visibility_detector/visibility_detector.dart';

class CommercialSpotWidget extends ConsumerWidget {
  final CommercialSpot spot;
  final bool highlight;

  const CommercialSpotWidget({
    super.key,
    required this.spot,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return VisibilityDetector(
      key: Key(spot.id),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction > 0.5) {
          if (!adViewSessionManager.hasViewed(spot.id)) {
            ref.read(analyticsServiceProvider).logCommercialSpotView(spot);
            ref.read(adsStateProvider.notifier).incrementCommercialSpotViewCount(spot.id);
            adViewSessionManager.markAsViewed(spot.id);
          }
        }
      },
      child: Card(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Container(
        height: highlight ? 90 : 80,
        decoration: BoxDecoration(
          color: AppStyle.black,
          border: Border.all(
            color: AppStyle.pink,
            width: highlight ? 2.0 : 1.0,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: SizedBox(
                width: double.maxFinite,
                child: Image.network(
                  spot.image,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: Container(
                color: const Color.fromARGB(200, 0, 0, 0),
                width: double.maxFinite,
                height: double.maxFinite,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spot.name,
                    style: AppStyle.activityName,
                  ),
                  gapH10,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.map_outlined,
                        color: AppStyle.pink,
                      ),
                      gapW10,
                      Text(
                        spot.address,
                        style: AppStyle.activitySubName.copyWith(
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                height: 24,
                width: 100,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppStyle.pink,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
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
            ),
          ],
        ),
      ),
      ),
    );
  }
}