import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Map<String, String> appTexts = {
  'auth-greet-title': "Heippa,",
  'auth-greet-subtitle':
      "'Hauska tutustua, aika upgreidata sosiaalinen elämäsi?'",
  'upgrade-social-life': "Upgreidaa sosiaalinen elämäsi",
  'lets-start': "Aloitetaan!",
  'login-apple': "Kirjaudu käyttäen Apple ID:tä",
  'login-google': "Kirjaudu käyttäen Googlea",
  'login-phone': "Kirjaudu puhelinnumerolla",
  'or': "Tai",
};

t(String key) {
  if (kDebugMode && appTexts[key] == null) {
    debugPrint("Key $key not found in appTexts.");
  }
  return appTexts[key] ?? key;
}
