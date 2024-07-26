import 'package:flutter/material.dart';
import 'package:miitti_app/constants/miitti_theme.dart';

/// A widget that displays a gradient background image.
class BackgroundGradient extends StatelessWidget {
  const BackgroundGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            Graphics.backgroundOverlay,
          ),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
