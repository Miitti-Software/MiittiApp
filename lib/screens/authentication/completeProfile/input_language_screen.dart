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
    final ScrollController scrollController = ScrollController();

    return ConfigScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text(config.get<String>('input-languages-title'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSizes.minVerticalDisclaimerPadding),
          Text(config.get<String>('input-languages-disclaimer'), style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSizes.verticalSeparationPadding),

          ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              physics: const ClampingScrollPhysics(),
            ),
            child: RawScrollbar(
              thumbVisibility: true,
              trackVisibility: true,
              thumbColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              trackColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              radius: const Radius.circular(10),
              thickness: 3,
              trackRadius: const Radius.circular(10),
              controller: scrollController,
              child: SingleChildScrollView(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(3, (rowIndex) {
                    int itemsPerRow = (Language.values.length / 3).ceil();
                    int startIndex = rowIndex * itemsPerRow;
                    int endIndex = (rowIndex + 1) * itemsPerRow;
                    
                    return Row(
                      children: [
                        for (Language language in Language.values.sublist(
                          startIndex,
                          endIndex.clamp(0, Language.values.length)
                        ))
                          ChoiceButton(
                            text: config.get<String>(language.code),
                            isSelected: selectedLanguages.contains(language),
                            onSelected: (_) {
                              setState(() {
                                if (selectedLanguages.contains(language)) {
                                  selectedLanguages.remove(language);
                                } else {
                                  selectedLanguages.add(language);
                                }
                              });
                            },
                          ),
                      ],
                    );
                  }),
                ),
              ),
            ),
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