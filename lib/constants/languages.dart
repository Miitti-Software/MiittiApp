enum Language { en, fi, sv, se, et, ru, uk, de, fr, es, pt, it, da, no, nl, sq, sl, zh, vi, ar, so, fa, ku, th, ko, ja, tr, la, eo, fse, swl, ase }

extension LanguageExtension on Language {
  String get name {
    switch (this) {
      case Language.en:
        return 'English';
      case Language.fi:
        return 'Suomi';
      case Language.sv:
        return 'Svenska';
      case Language.se:
        return 'Sami';
      case Language.et:
        return 'Eesti';
      case Language.ru:
        return 'Русский';
      case Language.uk:
        return 'Українська';
      case Language.de:
        return 'Deutsch';
      case Language.fr:
        return 'Français';
      case Language.es:
        return 'Español';
      case Language.pt: 
        return 'Português';
      case Language.it: 
        return 'Italiano';
      case Language.da:
        return 'Dansk';
      case Language.no:
        return 'Norsk';
      case Language.nl:
        return 'Nederlands';
      case Language.sq:
        return 'Shqip';
      case Language.sl:
        return 'Slovenščina';
      case Language.zh:
        return '中文';
      case Language.vi:
        return 'Tiếng Việt';
      case Language.ar:
        return 'العربية';
      case Language.so:
        return 'Soomaali';
      case Language.fa:
        return 'فارسی';
      case Language.ku:
        return 'Kurdî';
      case Language.th:
        return 'ไทย';
      case Language.ja:
        return '日本語';
      case Language.ko:
        return '한국어';
      case Language.tr:
        return 'Türkçe';
      case Language.la:
        return 'Latina';
      case Language.eo:
        return 'Esperanto';
      case Language.fse:
        return 'Suomalainen viittomakieli';
      case Language.swl:
        return 'Svenskt teckenspråk';
      case Language.ase:
        return 'American Sign Language';
    }
  }

  String get code {
    switch (this) {
      case Language.en:
        return 'en';
      case Language.fi:
        return 'fi';
      case Language.sv:
        return 'sv';
      case Language.se:
        return 'se';
      case Language.et:
        return 'et';
      case Language.ru:
        return 'ru';
      case Language.uk:
        return 'uk';
      case Language.de:
        return 'de';
      case Language.fr:
        return 'fr';
      case Language.es:
        return 'es';
      case Language.pt:
        return 'pt';
      case Language.it: 
        return 'it';
      case Language.da:
        return 'da';
      case Language.no:
        return 'no';
      case Language.nl:
        return 'nl';
      case Language.sq:
        return 'sq';
      case Language.sl:
        return 'sl';
      case Language.zh:
        return 'zh';
      case Language.vi:
        return 'vi';
      case Language.ar:
        return 'ar';
      case Language.so:
        return 'so';
      case Language.fa:
        return 'fa';
      case Language.ku:
        return 'ku';
      case Language.th:
        return 'th';
      case Language.ja:
        return 'ja';
      case Language.ko:
        return 'ko';
      case Language.tr:
        return 'tr';
      case Language.la:
        return 'la';
      case Language.eo:
        return 'eo';
      case Language.fse:
        return 'fse';
      case Language.swl:
        return 'swl';
      case Language.ase:
        return 'ase';
    }
  }
}