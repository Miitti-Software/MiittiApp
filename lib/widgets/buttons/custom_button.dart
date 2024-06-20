import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miitti_app/constants/app_style.dart';

class MyButton extends StatelessWidget {
  final String buttonText;
  final double? buttonWidth;
  final double? buttonHeight;

  final bool isWhiteButton;

  final Function() onPressed;

  const MyButton({
    required this.buttonText,
    this.isWhiteButton = false,
    this.buttonHeight = 50,
    this.buttonWidth = 350,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: buttonWidth?.w,
        height: buttonHeight?.h,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          border: Border.all(
            color: isWhiteButton
                ? const Color(0xFFFAFAFD).withOpacity(0.6)
                : AppStyle.pink,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isWhiteButton
                ? [
                    const Color(0xFFFAFAFD).withOpacity(0.1),
                    const Color(0xFFFAFAFD).withOpacity(0.1),
                  ]
                : [
                    AppStyle.pink.withOpacity(0.1),
                    AppStyle.red.withOpacity(0.1)
                  ],
          ),
        ),
        child: Center(
          child: Text(
            buttonText,
            style: AppStyle.body,
          ),
        ),
      ),
    );
  }
}
