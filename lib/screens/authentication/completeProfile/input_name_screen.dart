import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/config_screen.dart';
import 'package:miitti_app/widgets/error_snackbar.dart';
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
              const SizedBox(height: AppSizes.verticalSeparationPadding),
              FilledTextField(
                hintText: config.get<String>('input-name-placeholder'),
                controller: _controller,
                onSubmit: (value) {
                  userData.setName(_controller.text);
                  context.push('/login/complete-profile/birthday');
                },
              ),
              const SizedBox(height: AppSizes.minVerticalDisclaimerPadding),
              Text(config.get<String>('input-name-disclaimer'), style: Theme.of(context).textTheme.labelSmall),
              const Spacer(),
              ForwardButton(
                buttonText: config.get<String>('forward-button'),
                onPressed: () {
                  if (_controller.text.isNotEmpty) {
                    userData.setName(_controller.text);
                    context.push('/login/complete-profile/birthday');
                  } else {
                    ErrorSnackbar.show(context, config.get<String>('invalid-name-missing'));
                  }
                },
              ),
              const SizedBox(height: AppSizes.minVerticalPadding),
              BackwardButton(
                buttonText: config.get<String>('back-button'),
                onPressed: () => context.pop(),
              ),
              const SizedBox(height: AppSizes.minVerticalEdgePadding),
            ],
          ),
        );
      },
    );
  }
}
