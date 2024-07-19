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
}