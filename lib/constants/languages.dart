enum Language { en, fi }

extension LanguageExtension on Language {
  String get name {
    switch (this) {
      case Language.en:
        return 'English';
      case Language.fi:
        return 'Suomi';
    }
  }

  String get code {
    switch (this) {
      case Language.en:
        return 'en';
      case Language.fi:
        return 'fi';
    }
  }
}