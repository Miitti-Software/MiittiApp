import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/languages.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';
import 'package:miitti_app/widgets/buttons/choice_button.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/config_screen.dart';
import 'package:miitti_app/widgets/error_snackbar.dart';

/// A screen for the user to choose their gender from a list of radio buttons
class InputLanguagesScreen extends ConsumerStatefulWidget {
  const InputLanguagesScreen({super.key});

  @override
  _InputLanguagesScreenState createState() => _InputLanguagesScreenState();
}

class _InputLanguagesScreenState extends ConsumerState<InputLanguagesScreen> {
  List<Language> selectedLanguages = [];

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);
    final config = ref.watch(remoteConfigServiceProvider);

    return ConfigScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text(config.get<String>('input-languages-title'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSizes.minVerticalDisclaimerPadding),
          Text(config.get<String>('input-languages-disclaimer'), style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSizes.verticalSeparationPadding),

          Wrap(
          children: [
            for (Language language in Language.values)
              ChoiceButton(
                text: config.get<String>(language.code),
                isSelected: selectedLanguages.contains(language),
                onSelected: (bool selected) {
                  if (!selectedLanguages.contains(language)) {
                      setState(() {
                        selectedLanguages.add(language);
                      });
                  } else {
                    setState(() {
                      selectedLanguages.remove(language);
                    });
                  }
                },
              )
          ],
        ),

          
          const Spacer(),
          ForwardButton(buttonText: config.get<String>('forward-button'), onPressed: () {
            if (selectedLanguages.isNotEmpty) {
              userData.setUserLanguages(selectedLanguages);
              context.push('/');
            } else {
              ErrorSnackbar.show(context, config.get<String>('invalid-languages-missing'));
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