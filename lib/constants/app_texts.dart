Map<String, String> appTexts = {
  'upgrade-social-life': "Upgreidaa sosiaalinen elämäsi",
  'lets-start': "Aloitetaan!",
};

t(String key) {
  assert(appTexts[key] != null, "Key $key not found in appTexts");
  appTexts[key] ?? key;
}
