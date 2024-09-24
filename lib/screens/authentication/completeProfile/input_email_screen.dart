import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/services/analytics_service.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/config_screen.dart';
import 'package:miitti_app/widgets/fields/filled_textfield.dart';

class InputEmailScreen extends ConsumerWidget {
  const InputEmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(remoteConfigServiceProvider);
    final userData = ref.watch(userStateProvider).data;
    final controller = TextEditingController(text: userData.email);
    ref.read(analyticsServiceProvider).logScreenView('input_email_screen');

    return ConfigScreen(
      child: Column(
        children: [
          const Spacer(),
          Text(config.get<String>('input-email-title'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSizes.verticalSeparationPadding),
          // TODO: Add email validation
          FilledTextField(hintText: config.get<String>('input-email-placeholder'), controller: controller, onSubmit: (value) {
            userData.setEmail(controller.text);
            context.push('/');
          }),
          const SizedBox(height: AppSizes.minVerticalDisclaimerPadding),
          Text(config.get<String>('input-email-disclaimer'), style: Theme.of(context).textTheme.labelSmall),
          const Spacer(),
          ForwardButton(buttonText: config.get<String>('forward-button'), onPressed: () { 
            userData.setEmail(controller.text);
            context.push('/');
          }),
          const SizedBox(height: AppSizes.minVerticalPadding),
          BackwardButton(buttonText: config.get<String>('back-button'), onPressed: () => context.pop()),
          const SizedBox(height: AppSizes.verticalSeparationPadding),
        ],
      ),
    );
  }
}