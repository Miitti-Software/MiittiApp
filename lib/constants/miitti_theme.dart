import 'package:flutter/material.dart';

// Colors used for building the custom theme
const Color _pink = Color(0xFFE05494);
const Color _red = Color(0xFFF36269);
const Color _violet = Color(0xFF5615CE);
const Color _white = Color(0xFFFAFAFD);
const Color _black = Color(0xFF090215);
const Color _lightGrey = Color(0xFFA3A1AA);
const Color _darkSteel = Color(0xFF211B2C);
const Color _darkPurple = Color(0xFF14061B);
const Color _lightPurple = Color(0xFF3D1634);
const LinearGradient _pinkGradient = LinearGradient(
  colors: [
    _pink,
    _red,
  ],
);

final ThemeData miittiTheme = ThemeData(

  // Color scheme
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE05494)).copyWith(
    
    primary: _pink,
    primaryFixed: _pink,
    onPrimary: _white,
    onPrimaryFixed: _white,

    secondary: _red,
    secondaryFixed: _red,
    onSecondary: _white,
    onSecondaryFixed: _white,

    tertiary: _violet,
    tertiaryFixed: _violet,
    onTertiary: _white,
    onTertiaryFixed: _white,

    surface: _black,
    onSurface: _white,

    error: _red,
  ),

  scaffoldBackgroundColor: const Color(0xFF090215),

  // Font theming
  fontFamily: 'RedHatDisplay',

  textTheme: TextTheme(
    titleLarge: const TextStyle(          // ex title
      fontSize: 32,
      fontWeight: FontWeight.w600,
      color: _white,
    ),
    bodyMedium: const TextStyle(          // ex body
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: _white,
    ),
    labelLarge: TextStyle(          // ex hintText
      fontSize: 16,
      fontWeight: FontWeight.w300,
      color: _white.withOpacity(0.6),
    ),
    labelSmall: TextStyle(          // ex warning
      fontSize: 12,
      fontWeight: FontWeight.w300,
      color: _white.withOpacity(0.6),
    ),
    labelMedium: const TextStyle(         // ex question
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: _white,
    ),
    titleMedium: const TextStyle(         // ex activityName
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: _white,
    ),
    titleSmall: const TextStyle(          // ex activitySubName
      fontSize: 12,
      fontWeight: FontWeight.w300,
      color: _white,
    ),
  ),
);