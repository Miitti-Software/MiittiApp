import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/languages.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/services/analytics_service.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';
import 'package:miitti_app/widgets/buttons/choice_button.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/config_screen.dart';
import 'package:miitti_app/widgets/permanent_scrollbar.dart';
import 'package:miitti_app/widgets/overlays/error_snackbar.dart';

/// A screen for the user to choose their spoken languages from a side scrollable list of checkboxes
class InputLanguagesScreen extends ConsumerStatefulWidget {
  const InputLanguagesScreen({super.key});

  @override
  _InputLanguagesScreenState createState() => _InputLanguagesScreenState();
}

class _InputLanguagesScreenState extends ConsumerState<InputLanguagesScreen> {
  List<Language> selectedLanguages = [];
  final ScrollController scrollController = ScrollController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedLanguages = ref.read(userStateProvider).data.languages.toList();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userStateProvider).data;
    final userState = ref.read(userStateProvider.notifier);
    final config = ref.watch(remoteConfigServiceProvider);
    final isAnonymous = ref.watch(userStateProvider).isAnonymous;
    ref.read(analyticsServiceProvider).logScreenView('input_language_screen');

    return Stack(
      children: [
        ConfigScreen(
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
                child: PermanentScrollbar(
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
                                      userState.update((state) => state.copyWith(
                                        data: userData.removeLanguage(language)
                                      ));
                                    } else {
                                      selectedLanguages.add(language);
                                      userState.update((state) => state.copyWith(
                                        data: userData.addLanguage(language)
                                      ));
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
              if (isAnonymous)
                ForwardButton(
                  buttonText: config.get<String>('forward-button'),
                  onPressed: () {
                    if (selectedLanguages.isNotEmpty) {
                      context.push('/login/complete-profile/areas');
                    } else {
                      ErrorSnackbar.show(context, config.get<String>('invalid-languages-missing'));
                    }
                  },
                )
              else
                ForwardButton(
                  buttonText: config.get<String>('save-button'),
                  onPressed: () async {
                    if (selectedLanguages.isNotEmpty) {
                      setState(() {
                        isLoading = true;
                      });
                      userState.update((state) => state.copyWith(
                        data: userData.copyWith(languages: selectedLanguages)
                      ));
                      await userState.updateUserData();
                      setState(() {
                        isLoading = false;
                      });
                      context.pop();
                    } else {
                      ErrorSnackbar.show(context, config.get<String>('invalid-languages-missing'));
                    }
                  },
                ),
              const SizedBox(height: AppSizes.minVerticalPadding),
              BackwardButton(buttonText: config.get<String>('back-button'), onPressed: () => context.pop()),
              const SizedBox(height: AppSizes.minVerticalEdgePadding),
            ],
          ),
        ),
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}