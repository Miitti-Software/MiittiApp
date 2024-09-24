import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/services/analytics_service.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/widgets/buttons/auth_button.dart';
import 'package:miitti_app/widgets/config_screen.dart';

/// The sign in page for the app
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginAuthState();
}

class _LoginAuthState extends ConsumerState<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    final remoteConfig = ref.watch(remoteConfigServiceProvider);
    final authTitle = remoteConfig.get<String>('auth-title');
    final authSubtitle = remoteConfig.get<String>('auth-subtitle');
    ref.read(analyticsServiceProvider).logScreenView('login_screen');

    return ConfigScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 100),
          Center(child: SvgPicture.asset(AppGraphics.miittiLogo)),
          const SizedBox(height: 100),
          Text(authTitle, style: Theme.of(context).textTheme.titleLarge),
          Text(authSubtitle, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 20),
          if (Platform.isIOS) const AuthButton(isApple: true),
          if (Platform.isIOS) const SizedBox(height: 15),
          const AuthButton(),
        ],
      ),
    );
  }
}
