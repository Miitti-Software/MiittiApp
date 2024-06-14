import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/widgets/other_widgets.dart';
import 'package:miitti_app/screens/login/phone/phone_auth.dart';
import 'package:miitti_app/services/auth_provider.dart';
import 'package:provider/provider.dart';

class LoginAuth extends StatefulWidget {
  const LoginAuth({super.key});

  @override
  State<LoginAuth> createState() => _LoginAuthState();
}

class _LoginAuthState extends State<LoginAuth> {
  @override
  Widget build(BuildContext context) {
    final ap = Provider.of<AuthProvider>(context, listen: true);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppStyle.gapH50,

                //miitti-logo
                Center(child: OtherWidgets.getMiittiLogo),

                AppStyle.gapH50,

                //title
                Text(
                  'Heippa,',
                  style: AppStyle.title,
                ),

                //subtitle
                Text(
                  'Hauska tutustua, aika upgreidata sosiaalinen elämäsi?',
                  style: AppStyle.question,
                ),

                AppStyle.gapH20,

                //apple sign in
                Platform.isIOS
                    ? OtherWidgets.createAuthButton(
                        isApple: true,
                        onPressed: () {
                          //handle apple sign-in
                          ap.signInWithApple(context);
                        },
                      )
                    : Container(),

                AppStyle.gapH10,

                //google sign in
                OtherWidgets.createAuthButton(
                  isApple: false,
                  onPressed: () {
                    //handle google sign-in
                    ap.signInWithGoogle(context);
                  },
                ),

                AppStyle.gapH15,

                //pink divider
                OtherWidgets.createPinkDivider('Tai'),

                //sign with phone
                //TODO: Refactor button to own component
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PhoneAuth(),
                    ),
                  ),
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
                      'Kirjaudu puhelinnumerolla',
                      textAlign: TextAlign.center,
                      style: AppStyle.body.copyWith(
                        fontWeight: FontWeight.w300,
                        color: const Color.fromRGBO(255, 255, 255, 0.60),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
