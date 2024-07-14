import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/services/providers.dart';
import 'package:miitti_app/widgets/buttons/auth_button.dart';
import 'package:miitti_app/widgets/other_widgets.dart';
import 'package:miitti_app/widgets/safe_scaffold.dart';

class LoginAuth extends ConsumerStatefulWidget {
  const LoginAuth({super.key});

  @override
  ConsumerState<LoginAuth> createState() => _LoginAuthState();
}

class _LoginAuthState extends ConsumerState<LoginAuth> {
  @override
  Widget build(BuildContext context) {
    return SafeScaffold(
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
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
                ref.read(remoteConfigService).get<String>('auth-title'),
                style: AppStyle.title,
              ),
              //subtitle
              Text(
                ref.read(remoteConfigService).get<String>('auth-subtitle'),
                style: AppStyle.question,
              ),
              gapH20,
              //apple sign in
              if (Platform.isIOS) const AuthButton(apple: true),
              gapH10,
              // google sign in
              const AuthButton(),
            ],
          ),
        ),
      ),
    );
  }
}
