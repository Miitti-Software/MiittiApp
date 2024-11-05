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
import 'package:miitti_app/widgets/overlays/error_snackbar.dart';
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
    final userData = ref.read(userStateProvider).data;
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
        final userData = ref.watch(userStateProvider).data;
        final userState = ref.read(userStateProvider.notifier);
        ref.read(analyticsServiceProvider).logScreenView('input_name_screen');

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
                  userState.update((state) => state.copyWith(
                      data: userData.setName(_controller.text)
                  ));
                },
              ),
              const SizedBox(height: AppSizes.minVerticalDisclaimerPadding),
              Text(config.get<String>('input-name-disclaimer'), style: Theme.of(context).textTheme.labelSmall),
              const Spacer(),
              ForwardButton(
                buttonText: config.get<String>('forward-button'),
                onPressed: () {
                  if (_controller.text.isNotEmpty && isValidName(_controller.text)) {
                    userState.update((state) => state.copyWith(
                      data: userData.setName(_controller.text)
                    ));
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

  bool isValidName(String name) {
    final config = ref.read(remoteConfigServiceProvider);

    // Check against invalid names
    final invalidNames = config.get<Map>('invalid-names').values.toList();
    for (final invalidName in invalidNames) {
      if (name.toLowerCase() == invalidName.toLowerCase()) {
        return false;
      }
    }

    // Check against invalid regex patterns
    final invalidRegexps = config.get<Map>('invalid-regexps').values.toList();
    for (final pattern in invalidRegexps) {
      final regexp = RegExp(pattern);
      if (regexp.hasMatch(name)) {
        return false;
      }
    }

    return true;
  }
}


