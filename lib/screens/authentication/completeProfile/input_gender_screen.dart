import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/genders.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';
import 'package:miitti_app/widgets/buttons/choice_button.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/config_screen.dart';
import 'package:miitti_app/widgets/error_snackbar.dart';

/// A screen for the user to choose their gender from a list of radio buttons
class InputGenderScreen extends ConsumerStatefulWidget {
  const InputGenderScreen({super.key});

  @override
  _InputGenderScreenState createState() => _InputGenderScreenState();
}

class _InputGenderScreenState extends ConsumerState<InputGenderScreen> {
  Gender? selectedGender;

  @override
  void initState() {
    super.initState();
    selectedGender = ref.read(userDataProvider).gender;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);
    final config = ref.watch(remoteConfigServiceProvider);

    return ConfigScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text(config.get<String>('input-gender-title'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSizes.minVerticalDisclaimerPadding),
          Text(config.get<String>('input-gender-disclaimer'), style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSizes.verticalSeparationPadding),

          for (Gender gender in Gender.values)
            ChoiceButton(
              text: config.get<String>(gender.key),
              // Make the buttons behave like radio buttons by ensuring only one corresponding to the selected gender is selected at a time
              onSelected: (bool selected) {
                if (!selected) {
                  setState(() {
                    selectedGender = gender;
                    userData.setGender(selectedGender!);
                  });
                }
              },
              isSelected: gender == selectedGender,
            ),

          
          const Spacer(),
          ForwardButton(buttonText: config.get<String>('forward-button'), onPressed: () {
            if (selectedGender != null) {
              context.push('/login/complete-profile/languages');
            } else {
              ErrorSnackbar.show(context, config.get<String>('invalid-gender-missing'));
            }
          }),
          const SizedBox(height: AppSizes.minVerticalPadding),
          BackwardButton(buttonText: config.get<String>('back-button'), onPressed: () => context.pop()),
          const SizedBox(height: AppSizes.minVerticalEdgePadding),
        ],
      ),
    );
  }
}