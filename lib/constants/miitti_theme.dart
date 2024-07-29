import 'package:flutter/material.dart';

// Colors used for building the custom theme
class AppColors {
  static const Color pink = Color(0xFFE05494);
  static const Color red = Color(0xFFF36269);
  static const Color violet = Color(0xFF5615CE);
  static const Color white = Color(0xFFFAFAFD);
  static const Color black = Color(0xFF090215);
  static const Color lightGrey = Color(0xFFA3A1AA);
  static const Color darkSteel = Color(0xFF211B2C);
  static const Color darkPurple = Color(0xFF14061B);
  static const Color lightPurple = Color(0xFF3D1634);

  static const LinearGradient pinkGradient = LinearGradient(
    colors: [
      pink,
      red,
    ],
  );
}

class AppGraphics {
  static const String miittiLogo = 'images/miittiLogo.svg';
  static const String googleIcon = 'images/googleIcon.svg';
  static const String splashBackground = 'images/splashscreen.gif';
  static const String backgroundOverlay = 'images/background-gradient.png';
}

// Sizes used in building and shaping the app widgets
class AppSizes {
  static const double fullContentWidth = 350;
}

// Color scheme used for building the custom theme
final ColorScheme colorScheme = ColorScheme.fromSeed(seedColor: Colors.pink).copyWith(
  primary: AppColors.pink,
  primaryFixed: AppColors.pink,
  onPrimary: AppColors.white,
  onPrimaryFixed: AppColors.white,

  secondary: AppColors.red,
  secondaryFixed: AppColors.red,
  onSecondary: AppColors.white,
  onSecondaryFixed: AppColors.white,

  tertiary: AppColors.violet,
  tertiaryFixed: AppColors.violet,
  onTertiary: AppColors.white,
  onTertiaryFixed: AppColors.white,

  surface: AppColors.black,
  onSurface: AppColors.white,

  error: AppColors.red,
);

// Text theme used for building the custom theme
final TextTheme textTheme = TextTheme(
  titleLarge: TextStyle(          // ex title
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: colorScheme.onPrimary,
  ),
  bodyMedium: TextStyle(          // ex body
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: colorScheme.onPrimary,
  ),
  labelLarge: TextStyle(          // ex hintText
    fontSize: 16,
    fontWeight: FontWeight.w300,
    color: colorScheme.onPrimary.withOpacity(0.6),
  ),
  labelSmall: TextStyle(          // ex warning
    fontSize: 12,
    fontWeight: FontWeight.w300,
    color: colorScheme.onPrimary.withOpacity(0.6),
  ),
  labelMedium: TextStyle(         // ex question
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: colorScheme.onPrimary,
  ),
  titleMedium: TextStyle(         // ex activityName
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: colorScheme.onPrimary,
  ),
  titleSmall: TextStyle(          // ex activitySubName
    fontSize: 12,
    fontWeight: FontWeight.w300,
    color: colorScheme.onPrimary,
  ),
);

final ThemeData miittiTheme = ThemeData(

  // Color scheme
  colorScheme: colorScheme,
  scaffoldBackgroundColor: Colors.black,

  // Font theming
  fontFamily: 'RedHatDisplay',
  textTheme: textTheme,
);