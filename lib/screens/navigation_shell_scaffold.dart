import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/state/map_state.dart';
import 'package:miitti_app/widgets/custom_navigation_bar.dart';

class NavigationShellScaffold extends StatelessWidget {
  const NavigationShellScaffold({
    Key? key,
    required this.navigationShell,
  }) : super(key: key ?? const ValueKey('NavigationShellScaffold'));
  final StatefulNavigationShell navigationShell;

  void _goBranch(BuildContext context, WidgetRef ref, int index) {
    if (index == 1) {
      ref.read(mapStateProvider.notifier).setToggleIndex(0);
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: CustomNavigationBar(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) => _goBranch(context, ref, index),
          ),
        );
      },
    );
  }
}