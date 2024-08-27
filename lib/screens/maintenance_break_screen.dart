import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/widgets/config_screen.dart';

/// A screen for the user to choose their gender from a list of radio buttons
class MaintenanceBreakScreen extends ConsumerStatefulWidget {
  const MaintenanceBreakScreen({super.key});

  @override
  _MaintenanceBreakScreenState createState() => _MaintenanceBreakScreenState();
}

class _MaintenanceBreakScreenState extends ConsumerState<MaintenanceBreakScreen> {

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(remoteConfigServiceProvider);

    return ConfigScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text(config.get<String>('maintenance-break-text'), style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
        ],
      ),
    );
  }
}