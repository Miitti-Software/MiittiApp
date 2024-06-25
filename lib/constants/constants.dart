import 'package:flutter/material.dart';
import 'package:miitti_app/models/activity.dart';

// TODO: Load as a list from Firestore to enable translations
// Eventually make it load in order in order of recency and popularity
// Also wildcard emoji for custom events?
const Map<String, Activity> activities = {
  'sport': Activity(name: 'Liikkumaan', emojiData: '👟'),
  'outdoor': Activity(name: 'Ulkoilemaan', emojiData: '🌳'),
  'adventure': Activity(name: 'Seikkailemaan', emojiData: '🚀'),
  'ball': Activity(name: 'Pallopeleille', emojiData: '⚽️'),
  'racket': Activity(name: 'Mailapeleille', emojiData: '🏸'),
  'gym': Activity(name: 'Salille', emojiData: '🏋️'),
  'eat': Activity(name: 'Syömään', emojiData: '🍔'),
  'coffee': Activity(name: 'Kahville', emojiData: '☕️'),
  'hangout': Activity(name: 'Hengailemaan', emojiData: '💬'),
  'consert': Activity(name: 'Konserttiin', emojiData: '🎫'),
  'exhibition': Activity(name: 'Näyttelyyn', emojiData: '🏛️'),
  'teather': Activity(name: 'Teatteriin', emojiData: '🎭'),
  'movie': Activity(name: 'Leffaan', emojiData: '🎥'),
  'drink': Activity(name: 'Lasilliselle', emojiData: '🥂'),
  'boardgames': Activity(name: 'Lautapelit', emojiData: '🎲'),
  'study': Activity(name: 'Opiskelemaan', emojiData: '📚'),
  'travel': Activity(name: 'Matkustamaan', emojiData: '✈️'),
  'photography': Activity(name: 'Valokuvaamaan', emojiData: '📸'),
  'party': Activity(name: 'Bilettämään', emojiData: '🎉'),
  'barcrawl': Activity(name: 'Approilemaan', emojiData: '🍻'),
  'fest': Activity(name: 'Festareille', emojiData: '💃'),
  'sauna': Activity(name: 'Saunomaan', emojiData: '🧖‍♂️'),
  'ski': Activity(name: 'Laskettelemaan', emojiData: '🏂'),
  'iceskate': Activity(name: 'Luistelemaan', emojiData: '⛸️'),
  'roadtrip': Activity(name: 'Roadtripille', emojiData: '🚘'),
  'cycle': Activity(name: 'Pyöräilemään', emojiData: '🚲'),
  'gaming': Activity(name: 'Pelaamaan', emojiData: '🕹️'),
  'skateboard': Activity(name: 'Skeittaamaan', emojiData: '🛹'),
  'hike': Activity(name: 'Retkeilemään', emojiData: '🏕️'),
  'playdate': Activity(name: 'Leikkitreffeille', emojiData: '🛝'),
  'bookclub': Activity(name: 'Kirjakerhoon', emojiData: '📖'),
  'swim': Activity(name: 'Uimaan', emojiData: '🏊‍♂️'),
  'climb': Activity(name: 'Kiipeilemään', emojiData: '🧗‍♂️'),
  'bowling': Activity(name: 'Keilaamaan', emojiData: '🎳'),
  'golf': Activity(name: 'Golfaamaan', emojiData: '⛳️'),
  'sightseeing': Activity(name: 'Sightseeing', emojiData: '🌆'),
  'crafts': Activity(name: 'Askartelemaan', emojiData: '✂️'),
  'jam': Activity(name: 'Jameille', emojiData: '🎸'),
  'shopping': Activity(name: 'Shoppailemaan', emojiData: '🛍️'),
  'streetperformance': Activity(name: 'Katuesitys', emojiData: '👀'),
  'standup': Activity(name: 'Standup', emojiData: '🎤'),
  'parkour': Activity(name: 'Parkour', emojiData: '🤸'),
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
  "Salo",
  "Muu Suomi",
  "Ulkomaat",
];

const List<String> adminId = [
  'I1nASRt60QcQtzPOECyzM3WxxJ33',
  '43uacOhSQKOBxXEsEzTucaN7b5B2',
  'PCgz01aA7nbGAQigFsKyFnrHpMF2',
  'cyn5uJdDskdwGaZDvmNtztfxsRm2',
  'TI4jAfRnjnUWM46zwsL4pYUrF3Z2',
  'sGCB8PQbluYD8iD5xMx0bdwTrVE2',
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
