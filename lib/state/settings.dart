import 'package:miitti_app/constants/languages.dart';
import 'package:miitti_app/services/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/state/service_providers.dart';

// A class for managing user settings, including language preferences
class Settings {
  final LocalStorageService localStorageService;

  Settings(this.localStorageService);

  // Keys to access local storage values
  static const String languageKey = 'language';

  // Save the selected language enum to local storage
  Future<void> saveLanguage(Language language) async {
    await localStorageService.saveString(languageKey, language.name);
  }

  // Get the selected language enum from local storage
  Future<Language?> getLanguage() async {
    final languageStr = await localStorageService.getString(languageKey);
    return Language.values.firstWhere((language) => language.name == languageStr, orElse: () => Language.en);
  }
}

// Provider for the Settings
final settingsProvider = Provider<Settings>((ref) {
  final localStorageService = ref.watch(localStorageServiceProvider);
  return Settings(localStorageService);
});

// Provider for the selected language
final languageProvider = StateNotifierProvider<LanguageNotifier, Language>((ref) {
  final settings = ref.watch(settingsProvider);
  return LanguageNotifier(settings, ref);
});

class LanguageNotifier extends StateNotifier<Language> {
  final Settings settings;
  final Ref ref;

  LanguageNotifier(this.settings, this.ref) : super(Language.en) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final language = await settings.getLanguage();
    if (language != null) {
      state = language;
    }
  }

  Future<void> setLanguage(Language language) async {
    if (state != language) {
      state = language;
      await settings.saveLanguage(language);
    }
  }
}