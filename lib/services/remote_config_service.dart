import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';
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
  // A map to store the json config values
  final Map<String, dynamic> _configFiles = {};
  // A map to store the config values
  final Map<String, dynamic> _configValues = {};
  // A map to store the notification templates for all languages
  final Map<String, Map<String, dynamic>> _notificationTemplates = {};
  get configValues => _configValues;
  // List of remote config json file names to be loaded as defaults and fetched from Firebase - the same file names should be present both locally and in the Firebase console
  final List<String> _jsonFiles = ['app_texts', 'error_texts', 'areas', 'occupational_statuses', 'organizations', 'qa_category_1', 'qa_category_2', 'qa_category_3', 'activities', 'community_norms', 'activity_report_reasons', 'profile_report_reasons', 'notification_templates'];

  /// Getters for the different types of values that can be fetched from the remote config
  String getString(String key) => _remoteConfig.getString(key);
  bool getBool(String key) =>_remoteConfig.getBool(key);
  int getInt(String key) =>_remoteConfig.getInt(key);
  double getDouble(String key) =>_remoteConfig.getDouble(key);
  /// Generic getter for fetching values of any type that are defined in the json configuration files
  T get<T>(String key) {
    try {
      return _configValues[key] as T;
    } catch (e) {
      throw Exception('The key "$key" does not exist in the config values');
    }
  }

  /// Generic getter for fetching lists of key-value tuples of any value type that are defined in the json configuration files.
  /// The point is to be able to use the key values as identifiers in the app and the value as the actual value to be displayed or used in the app.
  List<Tuple2<String, T>> getTuplesList<T>(String key) {
    try {
      final dynamic file = _configFiles[key];
      return file.entries.map((entry) => Tuple2<String, T>(entry.key, entry.value as T)).toList().cast<Tuple2<String, T>>();
    } catch (e) {
      throw Exception('The key "$key" does not exist in the config files or is not a map: $e');
    }
  }

  /// Getter for activities that returns a list of tuples with the activity id, name and emoji
  List<Tuple2<String, Tuple2<String, String>>> getActivityTuples() {
    try {
      final dynamic file = _configFiles['activities'];
      return file.entries.map((entry) => Tuple2<String, Tuple2<String, String>>(entry.key, Tuple2<String, String>(entry.value['name'] as String, entry.value['emoji'] as String))).toList().cast<Tuple2<String, Tuple2<String, String>>>();
    } catch (e) {
      throw Exception('Error fetching activities: $e');
    }
  }

  Tuple2<String, String> getActivityTuple(String key) {
    try {
      final dynamic file = _configFiles['activities'];
      return Tuple2<String, String>(file[key]['name'] as String, file[key]['emoji'] as String);
    } catch (e) {
      throw Exception('Error fetching activity with key $key: $e');
    }
  }

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
    await _loadNotificationTemplates();
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
      try {
        final jsonString = await rootBundle.loadString('lib/constants/$file.json');
        final defaults = json.decode(jsonString) as Map<String, dynamic>;
        await _remoteConfig.setDefaults({file: json.encode(defaults)});
        _configFiles[file] = defaults;
        _configValues.addAll(defaults);
      } catch (error) {
        debugPrint('Error setting remote config defaults: $error with $file');
      }
    }
  }

  /// Fetch and activate the remote config values from Firebase
  Future<void> fetchAndActivate(language) async {
    bool success = await _remoteConfig.fetchAndActivate();
    while (!success) {
      success = await _remoteConfig.fetchAndActivate();
    }
    await _remoteConfig.ensureInitialized();
    _loadConfigValues(language);
  }

  // Load the config values fetched from Firebase corresponding to the selected language
  void _loadConfigValues(Language language) async {
    final languageSuffix = language.code;

    for (final file in _jsonFiles) {
      try {
        final jsonString = _remoteConfig.getString('${file}_$languageSuffix');
        final values = json.decode(jsonString) as Map<String, dynamic>;
        _configFiles[file] = values;
        _configValues.addAll(values);
      } catch (error) {
        debugPrint('Error loading remote config values: $error with $file');
      }
    }
    _configController.add(_configValues);
  }

  /// Load all language variants of notification_templates.json
  Future<void> _loadNotificationTemplates() async {
    for (final language in [Language.en, Language.fi]) {
      try {
        final languageSuffix = language.code;
        final jsonString = _remoteConfig.getString('notification_templates_$languageSuffix');
        final values = json.decode(jsonString) as Map<String, dynamic>;
        _notificationTemplates[languageSuffix] = values;
      } catch (error) {
        debugPrint('Error loading notification templates: $error');
      }
    }
  }

  /// Get a specific string in a specific language from notification_templates.json
  String getNotificationTemplateString(String key, Language language) {
    final languageSuffix = language.code;
    final values = _notificationTemplates[languageSuffix];
    if (values != null && values.containsKey(key)) {
      return values[key] as String;
    } else {
      throw Exception('The key "$key" does not exist in the notification templates for language "$languageSuffix"');
    }
  }

  /// Set up a listener for config updates in order to update the config values in real time
  void setupListener() {
    _remoteConfig.onConfigUpdated.listen((event) async {
      await ref.watch(languageProvider.notifier).loadLanguage();
      await fetchAndActivate(ref.read(languageProvider));
      await _loadNotificationTemplates();
    },
    onError: (error) {
      debugPrint('Remote config server error: $error');  // Sometimes Firebase's remote config server cannot be reached independently of the app in which case the app should continue to use the last fetched values
    });
  }

  /// Dispose the stream controller
  void dispose() {
    _configController.close();
  }
}
