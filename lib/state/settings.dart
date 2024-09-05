import 'package:location/location.dart';
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
  final LocalStorageService _localStorageService;
  static const String languageKey = 'language';

  LanguageNotifier(this._localStorageService) : super(Language.en) {
    loadLanguage();
  }

  Future<void> loadLanguage() async {
    final languageStr = await _localStorageService.getString(languageKey);
    if (languageStr != null) {
      state = Language.values.firstWhere((language) => language.code == languageStr, orElse: () => Language.en);
    }
  }

  Future<void> setLanguage(Language language) async {
    if (state != language) {
      state = language;
      await _localStorageService.saveString(languageKey, language.code);
    }
  }
}

final locationPermissionProvider = StateNotifierProvider<LocationPermissionNotifier, bool>((ref) {
  return LocationPermissionNotifier();
});

class LocationPermissionNotifier extends StateNotifier<bool> {
  final Location _liveLocation = Location();
  bool serviceEnabled = false;
  PermissionStatus permissionGranted = PermissionStatus.denied;

  LocationPermissionNotifier() : super(false) {
    setLocationPermission();
  }
  
  void setLocationPermission() async {
    serviceEnabled = await _liveLocation.serviceEnabled();
    permissionGranted = await _liveLocation.hasPermission();
    if (permissionGranted == PermissionStatus.granted || permissionGranted == PermissionStatus.grantedLimited) {
      state = true;
    } else {
      state = false;
    }
  }

  Future<bool> requestLocationService() async {
    serviceEnabled = await _liveLocation.serviceEnabled();
    if (serviceEnabled == true) {
      return true;
    }
    serviceEnabled = await _liveLocation.requestService();
    if (serviceEnabled == true) {
      return true;
    }
    return false;
  }

  Future<bool> requestLocationPermission() async {
    serviceEnabled = await _liveLocation.serviceEnabled();
    if (state == true) {
      return true;
    }
    if (permissionGranted != PermissionStatus.granted && permissionGranted != PermissionStatus.grantedLimited) {
      permissionGranted = await _liveLocation.requestPermission();
    }
    if (permissionGranted == PermissionStatus.granted || permissionGranted == PermissionStatus.grantedLimited) {
      state = true;
      return true;
    }
    return false;
  }
}