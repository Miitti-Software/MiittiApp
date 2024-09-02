import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/widgets/custom_navigation_bar.dart';

class NavigationShellScaffold extends StatelessWidget {
  const NavigationShellScaffold({
    Key? key,
    required this.navigationShell,
  }) : super(key: key ?? const ValueKey('NavigationShellScaffold'));
  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _goBranch,
      ),
    );
  }
}