import 'package:flutter/material.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/widgets/background_gradient.dart';

/// A widget that encapsulates characteristics common to configuration and onboarding screens such as background, content width and [SafeArea].
class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key, required this.child});
  
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const BackgroundGradient(),
          SafeArea(
            child: Center(
              child: SizedBox(
                width: AppSizes.fullContentWidth,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}