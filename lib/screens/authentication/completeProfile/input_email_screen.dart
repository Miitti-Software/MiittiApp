import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/config_screen.dart';
import 'package:miitti_app/widgets/fields/filled_textfield.dart';

// TODO: How is the scenario where the user is signed in with one email and then tries to sign in with another email handled?
class InputEmailScreen extends ConsumerWidget {
  const InputEmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(remoteConfigServiceProvider);
    final userData = ref.watch(userDataProvider);
    final controller = TextEditingController();

    return ConfigScreen(
      child: Column(
        children: [
          const Spacer(),
          Text(config.get<String>('input-email-title'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 30),
          // TODO: Add email validation
          FilledTextField(hintText: userData.email ??= config.get<String>('input-email-placeholder'), controller: controller, onSubmit: (value) {
            userData.setUserEmail(controller.text);
            context.push('/');
          }),
          const SizedBox(height: 8),
          Text(config.get<String>('input-email-disclaimer'), style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 30),
          ForwardButton(buttonText: config.get<String>('forward-button'), onPressed: () { 
            userData.setUserEmail(controller.text);
            context.push('/');
          }),
          const SizedBox(height: 10),
          BackwardButton(buttonText: config.get<String>('back-button'), onPressed: () => context.pop()),
          const Spacer(),
        ],
      ),
    );
  }
}