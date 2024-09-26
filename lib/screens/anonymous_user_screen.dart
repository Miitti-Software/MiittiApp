import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/widgets/config_screen.dart';
import 'package:miitti_app/widgets/permanent_scrollbar.dart';

class AnonymousUserScreen extends ConsumerWidget {
  const AnonymousUserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(remoteConfigServiceProvider);
    final deviceHeight = MediaQuery.of(context).size.height;

    return ConfigScreen(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: deviceHeight - 2 * AppSizes.minVerticalEdgePadding,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config.get<String>('anonymous-screen-title'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSizes.verticalSeparationPadding),
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: deviceHeight - 2 * AppSizes.minVerticalEdgePadding,
                  ),
                  child: PermanentScrollbar(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        config.get<String>('anonymous-screen-text'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
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
