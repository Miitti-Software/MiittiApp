import 'package:location/location.dart';
import 'package:miitti_app/constants/languages.dart';
import 'package:miitti_app/services/local_storage_service.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' as perm;

// Provider for the selected language
final languageProvider = StateNotifierProvider<LanguageNotifier, Language>((ref) {
  final localStorageService = ref.watch(localStorageServiceProvider);
  return LanguageNotifier(localStorageService);
});

class LanguageNotifier extends StateNotifier<Language> {
  final LocalStorageService _localStorageService;
  static const String languageKey = 'language';

  LanguageNotifier(this._localStorageService) : super(Language.fi) {
    loadLanguage();
  }

  Future<void> loadLanguage() async {
    final languageStr = await _localStorageService.getString(languageKey);
    if (languageStr != null) {
      state = Language.values.firstWhere((language) => language.code == languageStr, orElse: () => Language.fi);
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
  return LocationPermissionNotifier(ref);
});

class LocationPermissionNotifier extends StateNotifier<bool> {
  final Ref ref;
  final Location _liveLocation = Location();
  bool serviceEnabled = false;
  PermissionStatus permissionGranted = PermissionStatus.denied;

  LocationPermissionNotifier(this.ref) : super(false) {
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final savedState = await ref.read(localStorageServiceProvider).getBool('location_enabled') ?? false;
    state = savedState;
    if (state) {
      setLocationPermission(true);
    }
  }

  Future<void> _saveLocationState(bool enabled) async {
    await ref.read(localStorageServiceProvider).saveBool('location_enabled', enabled);
  }

  Future<void> setLocationPermission(bool enable) async {
    if (enable) {
      serviceEnabled = await _liveLocation.serviceEnabled();
      if (!serviceEnabled) {
        final serviceRequested = await requestLocationService();
        if (!serviceRequested) {
          state = false;
          await _saveLocationState(false);
          return;
        }
      }
      
      final permissionGranted = await requestLocationPermission();
      if (permissionGranted) {
        state = true;
        await _saveLocationState(true);
      } else {
        await perm.openAppSettings();
        final permission = await _liveLocation.hasPermission();
        if (permission == PermissionStatus.granted || permission == PermissionStatus.grantedLimited) {
          state = true;
          await _saveLocationState(true);
        } else {
          state = false;
          await _saveLocationState(false);
        }
      }
    } else {
      state = false;
      await _saveLocationState(false);
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

