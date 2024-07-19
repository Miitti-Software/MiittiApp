import 'package:flutter/material.dart';
import 'package:miitti_app/constants/languages.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// A class for interfacing with the local storage on the device and the values saved in it such as user preferences
class LocalStorageService {
  final Ref ref;
  final Future<SharedPreferences> _localStorage;

  LocalStorageService(this.ref) : _localStorage = SharedPreferences.getInstance();

  // Locally stored user preferences
  Language language = Language.en;

  // Keys to access local storage values
  static const String languageKey = 'language';

  // Save a string value to local storage
  Future<void> saveString(String key, String value) async {
    final prefs = await _localStorage;
    await prefs.setString(key, value);
  }

  // Get a string value from local storage
  Future<String?> getString(String key) async {
    final prefs = await _localStorage;
    return prefs.getString(key);
  }

  // Save the selected language enum to local storage
  Future<void> saveLanguage(Language language) async {
    await saveString(languageKey, language.name);
  }

  // Get the selected language enum from local storage
  Future<Language?> getLanguage() async {
    final languageStr = await getString(languageKey);
    return Language.values.firstWhere((language) => language.name == languageStr, orElse: () => Language.en);
  }
}