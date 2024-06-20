import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/services/providers.dart';

class AuthButton extends ConsumerWidget {
  final bool apple;

  const AuthButton({super.key, this.apple = false});

  @override
  Widget build(BuildContext context, ref) {
    return InkWell(
      onTap: () {
        if (apple) {
          ref.read(authService).signInWithApple(context);
        } else {
          ref.read(authService).signInWithGoogle(context);
        }
      },
      child: Container(
        height: 60.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            apple
                ? Icon(
                    Icons.apple,
                    size: 30.sp,
                  )
                : SvgPicture.asset(
                    'images/googleIcon.svg',
                  ),
            Text(
              apple
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
}
