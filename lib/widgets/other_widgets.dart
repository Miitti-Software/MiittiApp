import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:toggle_switch/toggle_switch.dart';

class OtherWidgets {
  //LOGIN INTRO PAGE WIDGETS
  static Widget getLanguagesButtons() {
    Set<String> appLanguages = {
      'Suomi',
      'English',
      'Svenska',
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (String language in appLanguages)
          Container(
            margin: EdgeInsets.only(right: 15.w, bottom: 45.h),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: const Color(0xFF2A1026),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: language == 'Suomi' ? AppStyle.pink : Colors.transparent,
                width: 1.0,
              ),
            ),
            child: Text(
              language,
              style: AppStyle.warning,
            ),
          ),
      ],
    );
  }

  //LOGIN PAGE WIDGETS
  static Widget getMiittiLogo = SvgPicture.asset(
    'images/miittiLogo.svg',
  );

  static Widget createAuthButton(
      {required bool isApple, required Function() onPressed}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: 60.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            isApple
                ? Icon(
                    Icons.apple,
                    size: 30.sp,
                  )
                : SvgPicture.asset(
                    'images/googleIcon.svg',
                  ),
            Text(
              isApple
                  ? 'Kirjaudu käyttäen Apple ID:tä'
                  : 'Kirjaudu käyttäen Googlea',
              textAlign: TextAlign.center,
              style: AppStyle.body
                  .copyWith(fontWeight: FontWeight.w700)
                  .copyWith(color: Colors.black, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  static Widget createPinkDivider(String text) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: AppStyle.pink,
            thickness: 2.0,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Text(
            text,
            style: AppStyle.body.copyWith(
              color: AppStyle.pink,
            ),
          ),
        ),
        const Expanded(
          child: Divider(
            color: AppStyle.pink,
            thickness: 2.0,
          ),
        ),
      ],
    );
  }

  static Future showLoadingDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: ((context) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppStyle.white,
          ),
        );
      }),
    );
  }

  //MAPS PAGE
  static Widget createToggleSwitch({
    required initialLabelIndex,
    required void Function(int?)? onToggle,
  }) {
    return ToggleSwitch(
      minWidth: 200.w,
      initialLabelIndex: initialLabelIndex,
      cornerRadius: 7,
      totalSwitches: 2,
      curve: Curves.linear,
      customTextStyles: [
        AppStyle.body.copyWith(fontSize: 16.sp),
      ],
      labels: const ['Näytä kartalla', 'Näytä listana'],
      activeBgColors: const [
        [Color(0XFFF34696), Color(0xFFF36269)],
        [Color(0XFFF34696), Color(0xFFF36269)],
      ],
      onToggle: onToggle,
    );
  }

  //INDEX PAGE
  Widget getFloatingButton({required void Function()? onPressed}) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          gradient: LinearGradient(
            colors: [
              AppStyle.pink,
              AppStyle.red,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child:
            Icon(Icons.add, size: 60.r, color: AppStyle.black.withOpacity(0.9)),
      ),
    );
  }

  //CREATE MIITTI PAGE
  Widget getCustomTextFormField(
      {required TextEditingController controller,
      required int maxLength,
      required int maxLines,
      required String hintText}) {
    return TextFormField(
      maxLength: maxLength,
      maxLines: maxLines,
      controller: controller,
      style: AppStyle.hintText.copyWith(color: Colors.white),
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        hintText: hintText,
        counterStyle: AppStyle.warning,
        hintStyle: AppStyle.hintText,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10.0,
          horizontal: 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
            color: AppStyle.pink,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
            color: AppStyle.pink,
            width: 2.0,
          ),
        ),
      ),
    );
  }
}
