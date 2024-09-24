import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/services/analytics_service.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/config_screen.dart';
import 'package:miitti_app/widgets/permanent_scrollbar.dart';
import 'package:url_launcher/url_launcher.dart';

/// A screen for notifying the user about an update and forcing them to update the app if necessary
class UpdateScreen extends ConsumerWidget {
  final bool forceUpdate;
  final String previousRoute;

  const UpdateScreen(this.forceUpdate, this.previousRoute, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(remoteConfigServiceProvider);
    final deviceHeight = MediaQuery.of(context).size.height;
    ref.read(analyticsServiceProvider).logScreenView('update_screen');

    return ConfigScreen(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: deviceHeight,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Text(
              forceUpdate
                  ? config.get<String>('update-required-title')
                  : config.get<String>('update-recommended-title'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.verticalSeparationPadding),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: deviceHeight,
                ),
                child: PermanentScrollbar(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      forceUpdate
                          ? config.get<String>('update-required-text')
                          : config.get<String>('update-recommended-text'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            ForwardButton(
              buttonText: config.get<String>('update-button'),
              onPressed: () async {
                final url = Uri.parse(Platform.isIOS
                    ? config.get<String>('update-app-store-link')
                    : config.get<String>('update-play-store-link'));
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  throw 'Could not launch $url';
                }
              },
            ),
            if (!forceUpdate) ...[
              const SizedBox(height: AppSizes.minVerticalPadding),
              BackwardButton(
                buttonText: config.get<String>('update-skip-button'),
                onPressed: () async {
                  context.go(previousRoute);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
