import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/constants/app_texts.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:miitti_app/services/service_providers.dart';
import 'package:miitti_app/widgets/other_widgets.dart';

class AuthButton extends ConsumerWidget {
  final bool apple;

  const AuthButton({super.key, this.apple = false});

  @override
  Widget build(BuildContext context, ref) {
    return InkWell(
      onTap: () async {
        bool signInSuccess;
        showLoadingDialog(context); // Show loading dialog

        if (apple) {
          signInSuccess = await ref.read(authService).signInWithApple();
        } else {
          signInSuccess = await ref.read(authService).signInWithGoogle();
        }

        Navigator.of(context).pop(); // Dismiss loading dialog

        if (signInSuccess) {
          ref.read(authService).afterSigning(context);
        } else {
          showSnackBar(context, "${t('login-error')}", AppStyle.red);
        }
      },
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            apple
                ? const Icon(
                    Icons.apple,
                    size: 30,
                  )
                : SvgPicture.asset(
                    'images/googleIcon.svg',
                  ),
            Text(
              apple
                  ? ref.read(remoteConfigService).get<String>('auth-apple')
                  : ref.read(remoteConfigService).get<String>('auth-google'),
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
