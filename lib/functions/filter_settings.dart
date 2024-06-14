import 'package:shared_preferences/shared_preferences.dart';

class FilterSettings {
  bool sameGender;
  bool multiplePeople;
  double minAge;
  double maxAge;
  double distance;

  FilterSettings({
    this.sameGender = false,
    this.multiplePeople = true,
    this.minAge = 18,
    this.maxAge = 60,
    this.distance = 50,
  });

  // To save these settings
  savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sameGender', sameGender);
    await prefs.setBool('multiplePeople', multiplePeople);
    await prefs.setDouble('minAge', minAge);
    await prefs.setDouble('maxAge', maxAge);
    await prefs.setDouble('distance', distance);
  }

  // To load these settings
  loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    sameGender = prefs.getBool('sameGender') ?? false;
    multiplePeople = prefs.getBool('multiplePeople') ?? true;
    minAge = prefs.getDouble('minAge') ?? 18;
    maxAge = prefs.getDouble('maxAge') ?? 60;
    distance = prefs.getDouble('distance') ?? 50;
  }
}
