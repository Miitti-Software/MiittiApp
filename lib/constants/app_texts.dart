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
  assert(appTexts[key] != null, "Key $key not found in appTexts");
  appTexts[key] ?? key;
}
