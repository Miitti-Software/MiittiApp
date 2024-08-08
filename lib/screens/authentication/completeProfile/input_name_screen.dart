import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/config_screen.dart';
import 'package:miitti_app/widgets/fields/filled_textfield.dart';

class InputNameScreen extends ConsumerStatefulWidget {
  const InputNameScreen({super.key});

  @override
  _InputNameScreenState createState() => _InputNameScreenState();
}

class _InputNameScreenState extends ConsumerState<InputNameScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize the controller with the user's name
    final userData = ref.read(userDataProvider);
    _controller = TextEditingController(text: userData.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final config = ref.watch(remoteConfigServiceProvider);
        final userData = ref.watch(userDataProvider);

        return ConfigScreen(
          child: Column(
            children: [
              const Spacer(),
              Text(config.get<String>('input-name-title'), style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 30),
              FilledTextField(
                hintText: config.get<String>('input-name-placeholder'),
                controller: _controller,
                onSubmit: (value) {
                  userData.setUserName(_controller.text);
                  context.push('/login/complete-profile/birthday');
                },
              ),
              const SizedBox(height: 8),
              Text(config.get<String>('input-name-disclaimer'), style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 30),
              ForwardButton(
                buttonText: config.get<String>('forward-button'),
                onPressed: () {
                  userData.setUserName(_controller.text);
                  context.push('/login/complete-profile/birthday');
                },
              ),
              const SizedBox(height: 10),
              BackwardButton(
                buttonText: config.get<String>('back-button'),
                onPressed: () => context.pop(),
              ),
              const Spacer(),
            ],
          ),
        );
      },
    );
  }
}
