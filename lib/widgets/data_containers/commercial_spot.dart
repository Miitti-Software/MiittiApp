import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/services/analytics_service.dart';
import 'package:miitti_app/state/ads_state.dart';
import 'package:miitti_app/state/service_providers.dart';
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
    final config = ref.watch(remoteConfigServiceProvider);
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
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
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
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        spot.address,
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
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
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  config.get<String>('commercial-spot-banner-text'),
                  style: const TextStyle(
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