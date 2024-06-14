import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppStyle {
  static const Color pink = Color(0xFFE05494);
  static const Color red = Color(0xFFF36269);
  static const Color orange = Color(0xFFF17517);
  static const Color purple = Color(0xFF5615CE);
  static const Color white = Color(0xFFFAFAFD);
  static const Color black = Color(0xFF090215);
  static const Color lavenderColor = Color(0xFFE6E6FA);
  static const Color darkPurpleColor = Color(0xFF220060);
  static const Color purpleColor = Color(0xFF5615CE);
  static const Color lightPurpleColor = Color(0xFFC3A3FF);
  static const Color yellowColor = Color(0xFFFED91E);
  static const Color orangeColor = Color(0xFFF17517);
  static const Color lightOrangeColor = Color(0xFFF59B57);
  static const Color darkOrangeColor = Color(0xFFF27052);
  static const Color lightRedColor = Color(0xFFF36269);
  static const Color pinkColor = Color(0xFFF45087);
  static const Color wineColor = Color(0xFF180B31);
  static const Color transparentPurple = Color.fromARGB(100, 86, 21, 206);

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

  static TextStyle textField = TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.w300,
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

  static final gapW5 = SizedBox(width: 5.w);
  static final gapW8 = SizedBox(width: 8.w);
  static final gapW10 = SizedBox(width: 10.w);
  static final gapW15 = SizedBox(width: 15.w);
  static final gapW20 = SizedBox(width: 20.w);

  static final gapW50 = SizedBox(width: 50.w);
  static final gapW100 = SizedBox(width: 100.w);

  static final gapH5 = SizedBox(height: 5.h);
  static final gapH8 = SizedBox(height: 8.h);
  static final gapH10 = SizedBox(height: 10.h);
  static final gapH15 = SizedBox(height: 15.h);
  static final gapH20 = SizedBox(height: 20.w);

  static final gapH50 = SizedBox(height: 50.h);
  static final gapH100 = SizedBox(height: 100.h);
}
