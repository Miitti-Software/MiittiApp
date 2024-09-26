enum Gender { male, female, other }

extension GenderExtension on Gender {
  String get key {
    switch (this) {
      case Gender.male:
        return 'male-gender';
      case Gender.female:
        return 'female-gender';
      case Gender.other:
        return 'other-gender';
    }
  }
}