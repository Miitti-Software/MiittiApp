import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/constants/genders.dart';
import 'package:miitti_app/constants/languages.dart';
import 'package:miitti_app/services/local_storage_service.dart';
import 'package:miitti_app/state/service_providers.dart';

// Provider for filter settings
final usersFilterSettingsProvider = StateNotifierProvider<FilterSettingsNotifier, FilterSettings>((ref) {
  final localStorageService = ref.watch(localStorageServiceProvider);
  return FilterSettingsNotifier(localStorageService);
});

class FilterSettings {
  int minAge;
  int maxAge;
  List<Gender> genders;
  bool sameArea;
  double maxDistance;
  List<Language> languages;
  List<String> interests;

  FilterSettings({
    this.minAge = 18,
    this.maxAge = 100,
    this.genders = const [Gender.male, Gender.female, Gender.other],
    this.sameArea = true,
    this.maxDistance = 10000,
    this.languages = const [Language.fi, Language.en, Language.sv],
    this.interests = const ['adventure', 'gaming', 'climbing', 'excercise', 'music', 'reading', 'sports', 'traveling'],
  });
}

class FilterSettingsNotifier extends StateNotifier<FilterSettings> {
  final LocalStorageService _localStorageService;
  static const String minAgeKey = 'minAgeUF';
  static const String maxAgeKey = 'maxAgeUF';
  static const String gendersKey = 'gendersUF';
  static const String sameLocationKey = 'sameAreaUF';
  static const String maxDistanceKey = 'maxDistanceUF';
  static const String languagesKey = 'languagesUF';
  static const String categoriesKey = 'interestsUF';

  FilterSettingsNotifier(this._localStorageService) : super(FilterSettings()) {
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    state = FilterSettings(
      minAge: await _localStorageService.getInt(minAgeKey) ?? 18,
      maxAge: await _localStorageService.getInt(maxAgeKey) ?? 100,
      genders: (await _localStorageService.getStringList(gendersKey))?.map((elem) => Gender.values.firstWhere((e) => e.toString().split('.').last.toLowerCase() == elem.toLowerCase())).toList() ?? [],
      sameArea: await _localStorageService.getBool(sameLocationKey) ?? false,
      maxDistance: await _localStorageService.getDouble(maxDistanceKey) ?? 10000,
      languages: (await _localStorageService.getStringList(languagesKey))?.map((elem) => Language.values.firstWhere((e) => e.toString().split('.').last.toLowerCase() == elem.toLowerCase())).toList() ?? [],
      interests: await _localStorageService.getStringList(categoriesKey) ?? [],
    );
  }

  Future<void> savePreferences() async {
    await _localStorageService.saveInt(minAgeKey, state.minAge);
    await _localStorageService.saveInt(maxAgeKey, state.maxAge);
    await _localStorageService.saveStringList(gendersKey, state.genders.map((e) => e.toString()).toList());
    await _localStorageService.saveBool(sameLocationKey, state.sameArea);
    await _localStorageService.saveDouble(maxDistanceKey, state.maxDistance);
    await _localStorageService.saveStringList(languagesKey, state.languages.map((e) => e.toString()).toList());
    await _localStorageService.saveStringList(categoriesKey, state.interests);
  }

  void updatePreferences(FilterSettings settings) {
    state = settings;
    savePreferences();
  }
}