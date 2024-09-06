import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/constants/languages.dart';
import 'package:miitti_app/services/local_storage_service.dart';
import 'package:miitti_app/state/service_providers.dart';

// Provider for filter settings
final activitiesFilterSettingsProvider = StateNotifierProvider<FilterSettingsNotifier, FilterSettings>((ref) {
  final localStorageService = ref.watch(localStorageServiceProvider);
  return FilterSettingsNotifier(localStorageService);
});

class FilterSettings {
  bool onlySameGender;
  int minParticipants;
  int maxParticipants;
  int minAge;
  int maxAge;
  double maxDistance;
  bool includePaid;
  List<String> categories;
  List<Language> languages;

  FilterSettings({
    this.onlySameGender = false,
    this.minParticipants = 1,
    this.maxParticipants = 10,
    this.minAge = 18,
    this.maxAge = 100,
    this.maxDistance = 10000,
    this.includePaid = true,
    this.categories = const [],
    this.languages = const [],
  });
}

class FilterSettingsNotifier extends StateNotifier<FilterSettings> {
  final LocalStorageService _localStorageService;
  static const String sameGenderKey = 'onlySameGender';
  static const String minParticipantsKey = 'minParticipants';
  static const String maxParticipantsKey = 'maxParticipants';
  static const String minAgeKey = 'minAge';
  static const String maxAgeKey = 'maxAge';
  static const String maxDistanceKey = 'maxDistance';
  static const String paidKey = 'includePaid';
  static const String categoriesKey = 'categories';
  static const String languagesKey = 'languages';

  FilterSettingsNotifier(this._localStorageService) : super(FilterSettings()) {
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    state = FilterSettings(
      onlySameGender: await _localStorageService.getBool(sameGenderKey) ?? false,
      minParticipants: await _localStorageService.getInt(minParticipantsKey) ?? 1,
      maxParticipants: await _localStorageService.getInt(maxParticipantsKey) ?? 10,
      minAge: await _localStorageService.getInt(minAgeKey) ?? 18,
      maxAge: await _localStorageService.getInt(maxAgeKey) ?? 100,
      maxDistance: await _localStorageService.getDouble(maxDistanceKey) ?? 10000,
      includePaid: await _localStorageService.getBool(paidKey) ?? false,
      categories: await _localStorageService.getStringList(categoriesKey) ?? [],
      languages: (await _localStorageService.getStringList(languagesKey))?.map((elem) => Language.values.firstWhere((e) => e.toString().split('.').last.toLowerCase() == elem.toLowerCase())).toList() ?? [],
    );
  }

  Future<void> savePreferences() async {
    await _localStorageService.saveBool(sameGenderKey, state.onlySameGender);
    await _localStorageService.saveInt(minParticipantsKey, state.minParticipants);
    await _localStorageService.saveInt(maxParticipantsKey, state.maxParticipants);
    await _localStorageService.saveInt(minAgeKey, state.minAge);
    await _localStorageService.saveInt(maxAgeKey, state.maxAge);
    await _localStorageService.saveDouble(maxDistanceKey, state.maxDistance);
    await _localStorageService.saveBool(paidKey, state.includePaid);
    await _localStorageService.saveStringList(categoriesKey, state.categories);
    await _localStorageService.saveStringList(languagesKey, state.languages.map((e) => e.toString()).toList());
  }

  void updatePreferences(FilterSettings settings) {
    state = settings;
    savePreferences();
  }
}