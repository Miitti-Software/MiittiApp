import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/constants/languages.dart';
import 'package:miitti_app/state/settings.dart';

/// Radio buttons for selecting the language.
class LanguageRadioButtons extends ConsumerStatefulWidget {
  const LanguageRadioButtons({super.key});

  @override
  _LanguageRadioButtonsState createState() => _LanguageRadioButtonsState();
}

class _LanguageRadioButtonsState extends ConsumerState<LanguageRadioButtons> {
  @override
  Widget build(BuildContext context) {
    final selectedLanguage = ref.watch(languageProvider);
    final languageOptions = Language.values.where((language) => language == Language.en || language == Language.fi);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: languageOptions.map((language) {
        final languageName = language.name;
        return GestureDetector(
          onTap: () {
            ref.read(languageProvider.notifier).setLanguage(language);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: language == selectedLanguage ? Theme.of(context).primaryColor : Colors.transparent,
                width: 1.0,
              ),
            ),
            child: Text(
              languageName,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        );
      }).toList(),
    );
  }
}