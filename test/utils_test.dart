import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miitti_app/utils/utils.dart';

void main() {
  test('validatePhoneNumber should return true for valid phone numbers', () {
    // Arrange
    final validPhoneNumbers = [
      '+12345678901',
      '+358123456789',
      '+1123456789013',
    ];

    // Act & Assert
    for (final phoneNumber in validPhoneNumbers) {
      expect(validatePhoneNumber(phoneNumber), true);
    }
  });

  test('validatePhoneNumber should return false for invalid phone numbers', () {
    // Arrange
    final invalidPhoneNumbers = [
      '',
      '12345678901',
      '+1234567890',
      '+123456789012345',
      '+12345678901a',
    ];

    // Act & Assert
    for (final phoneNumber in invalidPhoneNumbers) {
      expect(validatePhoneNumber(phoneNumber), false);
    }
  });

  test('calculateAge should return the correct age', () {
    // Arrange
    const birthDateString = '23/07/2000';
    const expectedAge = 23;

    // Act
    final age = calculateAge(birthDateString);

    // Assert
    expect(age, expectedAge);
  });

  test('daysSince should return the correct number of days', () {
    // Arrange
    final timestamp =
        Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5)));
    const expectedDays = -5;

    // Act
    final days = daysSince(timestamp);

    // Assert
    expect(days, expectedDays);
  });

  test('timestampToString should return the correct string representation', () {
    // Arrange
    final timestamp = Timestamp.fromDate(DateTime(2022, 12, 25, 10, 30));
    const expectedString = '25.12. klo 10:30';

    // Act
    final result = timestampToString(timestamp);

    // Assert
    expect(result, expectedString);
  });
}
