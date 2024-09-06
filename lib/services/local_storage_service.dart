import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A class for interfacing with the local storage on the device and the values saved in it such as user preferences.
class LocalStorageService {
  final Ref ref;
  final Future<SharedPreferences> _localStorage;

  LocalStorageService(this.ref) : _localStorage = SharedPreferences.getInstance();

  /// Save a string value to local storage.
  Future<void> saveString(String key, String value) async {
    final prefs = await _localStorage;
    await prefs.setString(key, value);
  }

  /// Get a string value from local storage.
  Future<String?> getString(String key) async {
    final prefs = await _localStorage;
    return prefs.getString(key);
  }

  /// Save a double value to local storage.
  Future<void> saveDouble(String key, double value) async {
    final prefs = await _localStorage;
    await prefs.setDouble(key, value);
  }

  /// Get a double value from local storage.
  Future<double?> getDouble(String key) async {
    final prefs = await _localStorage;
    return prefs.getDouble(key);
  }

  /// Save a boolean value to local storage.
  Future<void> saveBool(String key, bool value) async {
    final prefs = await _localStorage;
    await prefs.setBool(key, value);
  }

  /// Get a boolean value from local storage.
  Future<bool?> getBool(String key) async {
    final prefs = await _localStorage;
    return prefs.getBool(key);
  }

  /// Save an integer value to local storage.
  Future<void> saveInt(String key, int value) async {
    final prefs = await _localStorage;
    await prefs.setInt(key, value);
  }

  /// Get an integer value from local storage.
  Future<int?> getInt(String key) async {
    final prefs = await _localStorage;
    return prefs.getInt(key);
  }

  /// Save a list of strings to local storage.
  Future<void> saveStringList(String key, List<String> value) async {
    final prefs = await _localStorage;
    await prefs.setStringList(key, value);
  }

  /// Get a list of strings from local storage.
  Future<List<String>?> getStringList(String key) async {
    final prefs = await _localStorage;
    return prefs.getStringList(key);
  }

  /// Clear all values from local storage.
  Future<void> clear() async {
    final prefs = await _localStorage;
    await prefs.clear();
  }
}