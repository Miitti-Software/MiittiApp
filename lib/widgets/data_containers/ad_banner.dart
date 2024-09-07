import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/models/ad_banner_data.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:miitti_app/constants/app_style.dart';

class AdBanner extends ConsumerWidget {
  final AdBannerData adBannerData;

  const AdBanner({
    required this.adBannerData,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hyperlink = adBannerData.hyperlink;
    final image = adBannerData.image;
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
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  child: Text(
                    ref.watch(remoteConfigServiceProvider).get<String>('ad-banner-text'),
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