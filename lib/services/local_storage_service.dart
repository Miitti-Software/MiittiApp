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

  /// Clear all values from local storage.
  Future<void> clear() async {
    final prefs = await _localStorage;
    await prefs.clear();
  }
}