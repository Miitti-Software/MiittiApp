import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/config_screen.dart';
import 'package:miitti_app/widgets/fields/filled_textfield.dart';

class InputNameScreen extends ConsumerWidget {
  const InputNameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(remoteConfigServiceProvider);
    final userData = ref.watch(userDataProvider);
    final controller = TextEditingController(text: userData.name);

    return ConfigScreen(
      child: Column(
        children: [
          const Spacer(),
          Text(config.get<String>('input-name-title'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 30),
          FilledTextField(hintText: config.get<String>('input-name-placeholder'), controller: controller, onSubmit: (value) {
            userData.setUserName(controller.text);
            context.push('/login/complete-profile/email');
          }),
          const SizedBox(height: 8),
          Text(config.get<String>('input-name-disclaimer'), style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 30),
          ForwardButton(buttonText: config.get<String>('forward-button'), onPressed: () { 
            userData.setUserName(controller.text);
            context.push('/login/complete-profile/email');
          }),
          const SizedBox(height: 10),
          BackwardButton(buttonText: config.get<String>('back-button'), onPressed: () => context.pop()),
          const Spacer(),
        ],
      ),
    );
  }
}
