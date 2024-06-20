import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miitti_app/constants/app_style.dart';

class ChoiceButton extends StatelessWidget {
  const ChoiceButton(
      {super.key,
      required this.text,
      required this.isSelected,
      required this.onSelected});

  final String text;
  final bool isSelected;
  final Function(bool) onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onSelected(isSelected);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 15.h, right: 10.w),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xFF2A1026),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: isSelected ? AppStyle.pink : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Text(
          text,
          style: AppStyle.warning,
        ),
      ),
    );
  }
}
