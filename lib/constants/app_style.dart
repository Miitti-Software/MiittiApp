import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppStyle {
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

  static TextStyle title = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 32.sp,
    color: Colors.white,
  );

  static TextStyle body = TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle hintText = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w300,
    color: Colors.white.withOpacity(0.6),
  );

  static TextStyle warning = TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w300,
    color: Colors.white.withOpacity(0.6),
  );

  static TextStyle question = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  static TextStyle activityName = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static TextStyle activitySubName = TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w300,
    color: Colors.white,
  );
}
