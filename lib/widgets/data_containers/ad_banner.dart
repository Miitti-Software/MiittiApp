import 'dart:async';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/models/ad_banner_data.dart';
import 'package:miitti_app/services/analytics_service.dart';
import 'package:miitti_app/services/cache_manager_service.dart';
import 'package:miitti_app/state/ads_state.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Dynamically scaling full-width ad banner with minimum aspect ratio of 16/9 and a hyperlink
class AdBanner extends ConsumerWidget {
  final AdBannerData adBannerData;
  final double minAspectRatio = 16 / 9;

  const AdBanner({
    required this.adBannerData,
    super.key,
  });

  Future<Size> _getImageSize(String imageUrl) async {
    final image = CachedNetworkImageProvider(
      imageUrl,
      cacheManager: ProfilePicturesCacheManager(),
    );
    final completer = Completer<ui.Image>();
    final listener = ImageStreamListener((info, _) {
      if (!completer.isCompleted) {
        completer.complete(info.image);
      }
    });
    image.resolve(const ImageConfiguration()).addListener(listener);
    final loadedImage = await completer.future;
    return Size(loadedImage.width.toDouble(), loadedImage.height.toDouble());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hyperlink = adBannerData.hyperlink;
    final imageUrl = adBannerData.image;

    return VisibilityDetector(
      key: Key(adBannerData.id),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction > 0.5) {
          if (!adViewSessionManager.hasViewed(adBannerData.id)) {
            ref.read(analyticsServiceProvider).logBannerAdView(adBannerData);
            ref.read(adsStateProvider.notifier).incrementAdBannerViewCount(adBannerData.id);
            adViewSessionManager.markAsViewed(adBannerData.id);
          }
        }
      },
      child: GestureDetector(
        onTap: () async {
          ref.read(analyticsServiceProvider).logBannerAdClicked(adBannerData);
          ref.read(adsStateProvider.notifier).incrementAdBannerClickCount(adBannerData.id);
          await launchUrl(Uri.parse(hyperlink));
        },
        child: Card(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          margin: const EdgeInsets.all(10.0),
          child: Container(
            width: AppSizes.fullContentWidth,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: FutureBuilder<Size>(
              future: _getImageSize(imageUrl),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                  final imageSize = snapshot.data!;
                  final imageAspectRatio = imageSize.width / imageSize.height;

                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final containerAspectRatio = constraints.maxWidth / constraints.maxHeight;
                            final usedAspectRatio = [containerAspectRatio, imageAspectRatio, minAspectRatio].reduce((a, b) => a > b ? a : b);

                            return AspectRatio(
                              aspectRatio: usedAspectRatio,
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withAlpha(200),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                          child: Text(
                            ref.watch(remoteConfigServiceProvider).get<String>('ad-banner-text'),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}