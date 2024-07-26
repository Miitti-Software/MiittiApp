import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/constants/languages.dart';
import 'package:miitti_app/state/settings.dart';

class LanguageRadioButtons extends ConsumerStatefulWidget {
  const LanguageRadioButtons({Key? key}) : super(key: key);

  @override
  _LanguageRadioButtonsState createState() => _LanguageRadioButtonsState();
}

class _LanguageRadioButtonsState extends ConsumerState<LanguageRadioButtons> {
  @override
  Widget build(BuildContext context) {
    final selectedLanguage = ref.watch(languageProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: Language.values.map((language) {
        final languageName = language.name;
        return GestureDetector(
          onTap: () {
            ref.read(languageProvider.notifier).setLanguage(language);
          },
          child: Container(
            margin: const EdgeInsets.only(right: 15, bottom: 45),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF2A1026),
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