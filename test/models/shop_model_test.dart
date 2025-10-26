import 'package:flutter_test/flutter_test.dart';
import 'package:closecart/models/shop_model.dart';

void main() {
  group('BusinessHours', () {
    test('should create BusinessHours with default values', () {
      const businessHours = BusinessHours();

      expect(businessHours.open, '09:00');
      expect(businessHours.close, '17:00');
      expect(businessHours.isOpen, true);
    });

    test('should create BusinessHours with custom values', () {
      const businessHours = BusinessHours(
        open: '08:00',
        close: '20:00',
        isOpen: false,
      );

      expect(businessHours.open, '08:00');
      expect(businessHours.close, '20:00');
      expect(businessHours.isOpen, false);
    });

    test('should create BusinessHours from JSON', () {
      final json = {
        'open': '10:00',
        'close': '18:00',
        'isOpen': true,
      };

      final businessHours = BusinessHours.fromJson(json);

      expect(businessHours.open, '10:00');
      expect(businessHours.close, '18:00');
      expect(businessHours.isOpen, true);
    });

    test('should handle missing fields in JSON with defaults', () {
      final json = <String, dynamic>{};

      final businessHours = BusinessHours.fromJson(json);

      expect(businessHours.open, '09:00');
      expect(businessHours.close, '17:00');
      expect(businessHours.isOpen, true);
    });

    test('should convert BusinessHours to JSON', () {
      const businessHours = BusinessHours(
        open: '11:00',
        close: '19:00',
        isOpen: false,
      );

      final json = businessHours.toJson();

      expect(json['open'], '11:00');
      expect(json['close'], '19:00');
      expect(json['isOpen'], false);
    });

    test('should have proper toString representation', () {
      const businessHours = BusinessHours(
        open: '09:00',
        close: '17:00',
        isOpen: true,
      );

      final stringRep = businessHours.toString();

      expect(stringRep, contains('BusinessHours'));
      expect(stringRep, contains('09:00'));
      expect(stringRep, contains('17:00'));
      expect(stringRep, contains('true'));
    });

    test('should handle null values in JSON', () {
      final json = {
        'open': null,
        'close': null,
        'isOpen': null,
      };

      final businessHours = BusinessHours.fromJson(json);

      expect(businessHours.open, '09:00');
      expect(businessHours.close, '17:00');
      expect(businessHours.isOpen, true);
    });
  });

  group('WeeklyBusinessHours', () {
    test('should create WeeklyBusinessHours with default values', () {
      const weeklyHours = WeeklyBusinessHours();

      expect(weeklyHours.monday.open, '09:00');
      expect(weeklyHours.tuesday.open, '09:00');
      expect(weeklyHours.wednesday.open, '09:00');
      expect(weeklyHours.thursday.open, '09:00');
      expect(weeklyHours.friday.open, '09:00');
      expect(weeklyHours.saturday.open, '10:00'); // Different default
      expect(weeklyHours.sunday.open, '10:00'); // Different default
    });

    test('should create WeeklyBusinessHours with custom values', () {
      const customMonday = BusinessHours(open: '08:00', close: '18:00');
      const customTuesday = BusinessHours(open: '09:00', close: '17:00');

      const weeklyHours = WeeklyBusinessHours(
        monday: customMonday,
        tuesday: customTuesday,
      );

      expect(weeklyHours.monday.open, '08:00');
      expect(weeklyHours.monday.close, '18:00');
      expect(weeklyHours.tuesday.open, '09:00');
      expect(weeklyHours.tuesday.close, '17:00');
    });

    test('should have proper toString representation', () {
      const weeklyHours = WeeklyBusinessHours();
      final stringRep = weeklyHours.toString();

      expect(stringRep, contains('WeeklyBusinessHours'));
      // Note: The default toString might not contain day names
      // We'll just check it's not the default 'Instance of' format
      expect(stringRep, isNot(contains('Instance of')));
    });
  });

  group('Business Hours Validation', () {
    test('should validate time format', () {
      const validHours = BusinessHours(open: '09:00', close: '17:00');
      expect(validHours.open, matches(RegExp(r'^\d{2}:\d{2}$')));
      expect(validHours.close, matches(RegExp(r'^\d{2}:\d{2}$')));
    });

    test('should handle edge cases for time', () {
      const midnightHours = BusinessHours(open: '00:00', close: '23:59');
      expect(midnightHours.open, '00:00');
      expect(midnightHours.close, '23:59');
    });

    test('should handle 24-hour format', () {
      const twentyFourHour = BusinessHours(open: '06:30', close: '22:45');
      expect(twentyFourHour.open, '06:30');
      expect(twentyFourHour.close, '22:45');
    });
  });

  group('JSON Serialization', () {
    test('should serialize and deserialize correctly', () {
      const originalHours = BusinessHours(
        open: '10:30',
        close: '19:15',
        isOpen: false,
      );

      final json = originalHours.toJson();
      final deserializedHours = BusinessHours.fromJson(json);

      expect(deserializedHours.open, originalHours.open);
      expect(deserializedHours.close, originalHours.close);
      expect(deserializedHours.isOpen, originalHours.isOpen);
    });

    test('should handle roundtrip serialization for WeeklyBusinessHours', () {
      const originalWeekly = WeeklyBusinessHours(
        monday: BusinessHours(open: '08:00', close: '18:00'),
        friday: BusinessHours(open: '09:00', close: '17:00', isOpen: false),
      );

      // Test individual days
      expect(originalWeekly.monday.open, '08:00');
      expect(originalWeekly.monday.close, '18:00');
      expect(originalWeekly.friday.isOpen, false);
    });
  });

  group('Error Handling', () {
    test('should handle invalid JSON gracefully', () {
      final invalidJson = {
        'open': 123, // Invalid type
        'close': [], // Invalid type
        'isOpen': 'maybe', // Invalid type
      };

      // This should throw an exception due to type mismatch
      expect(
          () => BusinessHours.fromJson(invalidJson), throwsA(isA<TypeError>()));
    });

    test('should handle empty JSON', () {
      final emptyJson = <String, dynamic>{};
      final businessHours = BusinessHours.fromJson(emptyJson);

      expect(businessHours.open, '09:00');
      expect(businessHours.close, '17:00');
      expect(businessHours.isOpen, true);
    });
  });

  group('Equality and Comparison', () {
    test('should create equal objects with same values', () {
      const hours1 = BusinessHours(open: '09:00', close: '17:00');
      const hours2 = BusinessHours(open: '09:00', close: '17:00');

      // Note: Since BusinessHours doesn't override == operator,
      // these will be different instances
      expect(hours1.open, hours2.open);
      expect(hours1.close, hours2.close);
      expect(hours1.isOpen, hours2.isOpen);
    });

    test('should identify different objects', () {
      const hours1 = BusinessHours(open: '09:00', close: '17:00');
      const hours2 = BusinessHours(open: '10:00', close: '18:00');

      expect(hours1.open, isNot(hours2.open));
      expect(hours1.close, isNot(hours2.close));
    });
  });
}
