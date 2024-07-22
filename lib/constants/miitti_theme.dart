import 'package:flutter/material.dart';

// Colors used for building the custom theme
class Colors {
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

// Spacing used for building the custom theme
class Insets {
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
}

final ThemeData miittiTheme = ThemeData(

  // Color scheme
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE05494)).copyWith(
    
    primary: Colors.pink,
    primaryFixed: Colors.pink,
    onPrimary: Colors.white,
    onPrimaryFixed: Colors.white,

    secondary: Colors.red,
    secondaryFixed: Colors.red,
    onSecondary: Colors.white,
    onSecondaryFixed: Colors.white,

    tertiary: Colors.violet,
    tertiaryFixed: Colors.violet,
    onTertiary: Colors.white,
    onTertiaryFixed: Colors.white,

    surface: Colors.black,
    onSurface: Colors.white,

    error: Colors.red,
  ),

  scaffoldBackgroundColor: const Color(0xFF090215),

  // Font theming
  fontFamily: 'RedHatDisplay',

  textTheme: TextTheme(
    titleLarge: const TextStyle(          // ex title
      fontSize: 32,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    bodyMedium: const TextStyle(          // ex body
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    labelLarge: TextStyle(          // ex hintText
      fontSize: 16,
      fontWeight: FontWeight.w300,
      color: Colors.white.withOpacity(0.6),
    ),
    labelSmall: TextStyle(          // ex warning
      fontSize: 12,
      fontWeight: FontWeight.w300,
      color: Colors.white.withOpacity(0.6),
    ),
    labelMedium: const TextStyle(         // ex question
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    titleMedium: const TextStyle(         // ex activityName
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    titleSmall: const TextStyle(          // ex activitySubName
      fontSize: 12,
      fontWeight: FontWeight.w300,
      color: Colors.white,
    ),
  ),
);