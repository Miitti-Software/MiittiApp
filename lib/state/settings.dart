import 'package:miitti_app/constants/languages.dart';
import 'package:miitti_app/services/local_storage_service.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for the selected language
final languageProvider = StateNotifierProvider<LanguageNotifier, Language>((ref) {
  final localStorageService = ref.watch(localStorageServiceProvider);
  return LanguageNotifier(localStorageService);
});

class LanguageNotifier extends StateNotifier<Language> {
  final LocalStorageService localStorageService;
  static const String languageKey = 'language';

  LanguageNotifier(this.localStorageService) : super(Language.en) {
    loadLanguage();
  }

  Future<void> loadLanguage() async {
    final languageStr = await localStorageService.getString(languageKey);
    if (languageStr != null) {
      state = Language.values.firstWhere((language) => language.code == languageStr, orElse: () => Language.en);
    }
  }

  Future<void> setLanguage(Language language) async {
    if (state != language) {
      state = language;
      await localStorageService.saveString(languageKey, language.code);
    }
  }
}