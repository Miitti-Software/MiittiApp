import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/state/settings.dart';

import '../constants/languages.dart';

/// A singleton class for interfacing with the Firebase Remote Config service to enable dynamic configuration of the texts, UI and features of the app
class RemoteConfigService {

  // A reference to the Riverpod state provider instantiating and initializing the class and providing global access to the Firebase Remote Config instance
  final Ref ref;

  // A private constructor to prevent instantiation of the class
  RemoteConfigService._(this.ref) : _remoteConfig = FirebaseRemoteConfig.instance;

  // Return the same static singleton instance of the class every time it is called if it already exists, otherwise create a new instance
  static RemoteConfigService? _instance;
  factory RemoteConfigService(ref) => _instance ??= RemoteConfigService._(ref);

  // The Firebase Remote Config instance
  final FirebaseRemoteConfig _remoteConfig;
  // A map to store the config values
  final Map<String, dynamic> _configValues = {};
  // List of remote config json file names to be loaded as defaults and fetched from Firebase - the same file names should be present both locally and in the Firebase console
  final List<String> _jsonFiles = ['app_texts']; // TODO: 'activities', 'question_cards'

  /// Getters for the different types of values that can be fetched from the remote config
  String getString(String key) => _remoteConfig.getString(key);
  bool getBool(String key) =>_remoteConfig.getBool(key);
  int getInt(String key) =>_remoteConfig.getInt(key);
  double getDouble(String key) =>_remoteConfig.getDouble(key);
  /// Generic getter for fetching values of any type that are defined in the json configuration files
  T get<T>(String key) => _configValues[key] as T;

  /// Get a list of maps of rich text values with keys "text" and "url" fetched from the remote config
  List<Map<String, dynamic>> getRichText(String key) {
    final richTextData = _configValues[key] as List<dynamic>;
    return richTextData.cast<Map<String, dynamic>>();
  }

  // Stream controller to broadcast config changes
  final _configController = StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of config changes
  Stream<Map<String, dynamic>> get configStream => _configController.stream;

  /// Initialize the Firebase Remote Config instance by setting defaults, config settings, fetching and activating the remote config values and setting up a listener for config updates
  Future<void> initialize() async {
    final language = ref.read(languageProvider);
    await _setDefaults();
    await _setConfigSettings();
    await fetchAndActivate(language);
    setupListener();
  }

  // Set the configuration settings for the Firebase Remote Config instance
  Future<void> _setConfigSettings() async => _remoteConfig.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 12),
    ),
  );

  // Load default values from local json files under lib/constants
  Future<void> _setDefaults() async {
    for (final file in _jsonFiles) {
      final jsonString = await rootBundle.loadString('lib/constants/$file.json');
      final defaults = json.decode(jsonString) as Map<String, dynamic>;
      await _remoteConfig.setDefaults({file: json.encode(defaults)});
      _configValues.addAll(defaults);
    }
  }

  /// Fetch and activate the remote config values from Firebase
  Future<void> fetchAndActivate(language) async {
    await _remoteConfig.fetchAndActivate();
    _loadConfigValues(language);
  }

  // Load the config values fetched from Firebase corresponding to the selected language
  void _loadConfigValues(Language language) async {
    final languageSuffix = language.code;

    for (final file in _jsonFiles) {
      final jsonString = _remoteConfig.getString('${file}_$languageSuffix');
      final values = json.decode(jsonString) as Map<String, dynamic>;
      _configValues.addAll(values);
    }
    _configController.add(_configValues);
  }

  /// Set up a listener for config updates in order to update the config values in real time
  void setupListener() {
    _remoteConfig.onConfigUpdated.listen((event) async {
      await ref.watch(languageProvider.notifier).loadLanguage();
      await fetchAndActivate(ref.read(languageProvider));
    });
  }

  /// Dispose the stream controller
  void dispose() {
    _configController.close();
  }
}
