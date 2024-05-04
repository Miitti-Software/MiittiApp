import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miitti_app/data/activity.dart';

class AppColors {
  static const Color backgroundColor = Color(0xFF090215);
  static const Color whiteColor = Color(0xFFFFFBF7);
  static const Color mixGradientColor = Color(0xFFEC5800);
  static const Color lavenderColor = Color(0xFFE6E6FA);
  static const Color darkPurpleColor = Color(0xFF220060);
  static const Color purpleColor = Color(0xFF5615CE);
  static const Color lightPurpleColor = Color(0xFFC3A3FF);
  static const Color yellowColor = Color(0xFFFED91E);
  static const Color orangeColor = Color(0xFFF17517);
  static const Color lightOrangeColor = Color(0xFFF59B57);
  static const Color darkOrangeColor = Color(0xFFF27052);
  static const Color lightRedColor = Color(0xFFF36269);
  static const Color pinkColor = Color(0xFFF45087);
  static const Color wineColor = Color(0xFF180B31);
  static const Color transparentPurple = Color.fromARGB(100, 86, 21, 206);
}

class Styles {
  static ButtonStyle buttonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30.0),
    ),
  );

  static TextStyle titleTextStyle = TextStyle(
    fontSize: 26.sp,
    fontFamily: 'Sora',
    color: AppColors.whiteColor,
    fontWeight: FontWeight.bold,
  );

  static TextStyle activityNameTextStyle = TextStyle(
    fontFamily: 'Rubik',
    fontSize: 19.sp,
    color: AppColors.whiteColor,
  );
  static TextStyle bodyTextStyle = TextStyle(
    fontSize: 21.sp,
    color: AppColors.whiteColor,
    fontFamily: 'Rubik',
  );

  static TextStyle sectionTitleStyle = TextStyle(
    fontFamily: 'Sora',
    fontSize: 22.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.whiteColor,
  );

  static TextStyle sectionSubtitleStyle = TextStyle(
    fontFamily: 'Rubik',
    fontSize: 14.sp,
    color: AppColors.whiteColor,
  );
}

const Map<String, Activity> activities = {
  'racket': Activity(name: 'Mailapeleille', emojiData: '🏸'),
  'party': Activity(name: 'Bilettämään', emojiData: '🎉'),
  'fest': Activity(name: 'Festareille', emojiData: '💃'),
  'golf': Activity(name: 'Golfaamaan', emojiData: '⛳️'),
  'hangout': Activity(name: 'Hengailemaan', emojiData: '💬'),
  'ball': Activity(name: 'Pallopeleille', emojiData: '⚽️'),
  'coffee': Activity(name: 'Kahville', emojiData: '☕️'),
  'consert': Activity(name: 'Konserttiin', emojiData: '🎫'),
  'drink': Activity(name: 'Lasilliselle', emojiData: '🥂'),
  'boardgames': Activity(name: 'Lautapelit', emojiData: '🎲'),
  'movie': Activity(name: 'Leffaan', emojiData: '🎥'),
  'sport': Activity(name: 'Liikkumaan', emojiData: '👟'),
  'travel': Activity(name: 'Matkaseuraa', emojiData: '✈️'),
  'study': Activity(name: 'Opiskelemaan', emojiData: '📚'),
  'gaming': Activity(name: 'Pelaamaan', emojiData: '🕹️'),
  'cycle': Activity(name: 'Pyöräilemään', emojiData: '🚲'),
  'adventure': Activity(name: 'Seikkailemaan', emojiData: '🚀'),
  'skateboard': Activity(name: 'Skeittaamaan', emojiData: '🛹'),
  'eat': Activity(name: 'Syömään', emojiData: '🍔'),
  'exhibition': Activity(name: 'Näyttelyyn', emojiData: '🏛️'),
  'teather': Activity(name: 'Teatteriin', emojiData: '🎭'),
  'swim': Activity(name: 'Uimaan', emojiData: '🏊‍♂️'),
  'outdoor': Activity(name: 'Ulkoilemaan', emojiData: '🌳'),
  'photography': Activity(name: 'Valokuvaamaan', emojiData: '📸'),
  'ski': Activity(name: 'Laskettelemaan', emojiData: '🏂'),
  'hike': Activity(name: 'Retkeilemään', emojiData: '🏕️'),
  'gym': Activity(name: 'Salille', emojiData: '🏋️'),
  'iceskate': Activity(name: 'Luistelemaan', emojiData: '⛸️'),
  'roadtrip': Activity(name: 'Roadtripille', emojiData: '🚘'),
  'climb': Activity(name: 'Kiipeilemään', emojiData: '🧗‍♂️'),
  'bowling': Activity(name: 'Keilaamaan', emojiData: '🎳')
};

const List<Activity> commercialActivities = [
  Activity(name: 'Liikunta', emojiData: '👟'),
  Activity(name: 'Bileet', emojiData: '🎉'),
  Activity(name: 'Festivaalit', emojiData: '💃'),
  Activity(name: 'Konsertti', emojiData: '🎫'),
  Activity(name: 'Ruoka', emojiData: '🍔'),
  Activity(name: 'Kahvila', emojiData: '☕️'),
  Activity(name: 'Taidenäyttely', emojiData: '🎨'),
  Activity(name: 'Työpaja', emojiData: '🔨'),
  Activity(name: 'Verkostoituminen', emojiData: '💬'),
  Activity(name: 'Muu kulttuuritapahtuma', emojiData: '🎭'),
  Activity(name: 'Muu tapahtuma', emojiData: '🥂'),
  Activity(name: 'Muu aktiviteetti', emojiData: '🎲'),
];

const List<String> questionOrder = [
  'Kuvailen itseäni näillä viidellä emojilla',
  'Kerro millainen tyyppi olet',
  'Persoonaani kuvaa parhaiten se, että',
  'Esittele itsesi viidellä emojilla',
  'Fakta, jota useimmat minusta eivät tiedä',
  'Mikä on horoskooppisi',
  'Olen uusien ihmisten seurassa yleensä',
  'Introvertti vai ekstrovertti',
  'Erikoisin taito, jonka osaan',
  'Mitä ilman et voisi elää',
  'Lempiruokani on ehdottomasti',
  'Mikä on lempiruokasi',
  'En voisi elää ilman',
  'Kerro yksi fakta itsestäsi',
  'Olen miestäni',
  'Erikoisin taito, jonka osaat',
  'Ottaisin mukaan autiolle saarelle',
  'Suosikkiartistini on',
  'Suosikkiartistisi',
  'Arvostan eniten ihmisiä, jotka',
  'Lempiharrastuksesi',
  'Ylivoimainen inhokkiruokani on',
  'Mitä ottaisit mukaan autiolle saarelle',
  'Lempiharrastukseni on',
  'Käytän vapaa-päiväni useimmiten',
  'Kerro hauskin vitsi, jonka tiedät',
  'Haluaisin kokeilla',
  'Missä maissa olet käynyt',
  'Harrastin lapsena ',
  'Mikä on inhokkiruokasi',
  'Harrastus, jota en ole vielä uskaltanut kokeilla',
  'Mitä tekisit, jos voittaisi miljoonan lotossa',
  'Haluaisin löytää',
  'Haluaisin matkustaa seuraavaksi',
  'Paras matkavinkkini on',
  'Koen olevani',
  'Mitä ilman et voisi elää',
  'Pahin pakkomielteeni on',
  'Mikä on lempiruokasi',
  'Suurin vahvuuteni on',
  'Kerro yksi fakta itsestäsi',
  'En ole parhaimmillani',
  'Erikoisin taito, jonka osaat',
  'Kiusallisin hetkeni oli, kun',
  'Suosikkiartistisi',
  'Olin viimeksi surullinen, koska',
  'Lempiharrastukseni',
  'En ole koskaan sanonut, että',
  'Mitä ottaisit mukaan autiolle saarelle',
  'Olen otettu, jos',
  'Kerro hauskin vitsi, jonka tiedät',
  'Ottaisin mukaan autiolle saarelle',
  'Olen onnellinen, koska',
  'Missä maissa olet käynyt',
  'Tänä vuonna haluan',
  'Mikä on inhokkiruokasi',
  'Mitä tekisit, jos voittaisi miljoonan lotossa'
];

const List<String> languages = [
  '🇫🇮',
  '🇸🇪',
  '🇬🇧',
];

const List<String> cities = [
  "Helsinki",
  "Espoo",
  "Tampere",
  "Vantaa",
  "Oulu",
  "Turku",
  "Jyväskylä",
  "Lahti",
  "Kuopio",
  "Pori",
  "Kouvola",
  "Joensuu",
  "Lappeenranta",
  "Hämeenlinna",
  "Vaasa",
  "Seinäjoki",
  "Rovaniemi",
  "Mikkeli",
  "Kotka",
  "Salo"
];

const List<String> adminId = [
  'I1nASRt60QcQtzPOECyzM3WxxJ33',
  '43uacOhSQKOBxXEsEzTucaN7b5B2',
  'PCgz01aA7nbGAQigFsKyFnrHpMF2',
  'cyn5uJdDskdwGaZDvmNtztfxsRm2',
  'TI4jAfRnjnUWM46zwsL4pYUrF3Z2',
];

const String mapboxAccess =
    'pk.eyJ1IjoibWlpdHRpYXBwIiwiYSI6ImNsaTBja21sazFtYWMzcW50NWd0cW40eTEifQ.FwjMEmDQD1Cj2KlaJuGTTA';

class Cutout extends StatelessWidget {
  const Cutout({
    super.key,
    required this.color,
    required this.child,
  });

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcOut,
      shaderCallback: (bounds) =>
          LinearGradient(colors: [color], stops: const [0.0])
              .createShader(bounds),
      child: child,
    );
  }
}
