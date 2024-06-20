import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/constants/app_texts.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:miitti_app/widgets/buttons/auth_button.dart';
import 'package:miitti_app/widgets/other_widgets.dart';
import 'package:miitti_app/screens/login/phone/phone_auth.dart';
import 'package:miitti_app/widgets/safe_scaffold.dart';

class LoginAuth extends StatefulWidget {
  const LoginAuth({super.key});

  @override
  State<LoginAuth> createState() => _LoginAuthState();
}

class _LoginAuthState extends State<LoginAuth> {
  @override
  Widget build(BuildContext context) {
    return SafeScaffold(
      SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              gapH50,
              //miitti-logo
              Center(child: getMiittiLogo),
              gapH50,
              //title
              Text(
                t('auth-greet-title'),
                style: AppStyle.title,
              ),
              //subtitle
              Text(
                t('auth-greet-subtitle'),
                style: AppStyle.question,
              ),
              gapH20,
              //apple sign in
              if (Platform.isIOS) const AuthButton(apple: true),
              gapH10,
              //google sign in
              const AuthButton(),
              gapH10,
              //pink divider
              createPinkDivider('Tai'),
              //sign with phone
              choosePhoneLogin(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget choosePhoneLogin(BuildContext context) {
    return GestureDetector(
      onTap: () => pushPage(context, const PhoneAuth()),
      child: Container(
        width: 350.w,
        margin: EdgeInsets.symmetric(
          vertical: 20.h,
          horizontal: 10.w,
        ),
        padding: EdgeInsets.symmetric(
          vertical: 8.w,
        ),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          border: Border.all(
            color: AppStyle.pink,
          ),
        ),
        child: Text(
          t('login-phone'),
          textAlign: TextAlign.center,
          style: AppStyle.body.copyWith(
            fontWeight: FontWeight.w300,
            color: AppStyle.lightGrey,
          ),
        ),
      ),
    );
  }
}
