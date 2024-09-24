import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/services/analytics_service.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/widgets/config_screen.dart';
import 'package:miitti_app/widgets/permanent_scrollbar.dart';

/// A screen for displaying maintenance break information
class MaintenanceBreakScreen extends ConsumerWidget {
  const MaintenanceBreakScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(remoteConfigServiceProvider);
    final deviceHeight = MediaQuery.of(context).size.height;
    ref.read(analyticsServiceProvider).logScreenView('maintenance_break_screen');

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
                config.get<String>('maintenance-break-title'),
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
                        config.get<String>('maintenance-break-text'),
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