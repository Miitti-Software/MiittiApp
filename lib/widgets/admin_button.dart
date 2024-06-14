import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miitti_app/constants/app_style.dart';

class AdminButton extends StatelessWidget {
  final Function()? onTap;

  const AdminButton({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(25.w),
        margin: EdgeInsets.symmetric(horizontal: 25.w),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Center(
          child: Text(
            'Kirjaudu Sisään',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 17.sp,
              color: AppStyle.white,
            ),
          ),
        ),
      ),
    );
  }
}
