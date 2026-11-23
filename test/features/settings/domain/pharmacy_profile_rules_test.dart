import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/settings/domain/pharmacy_profile_rules.dart';

void main() {
  group('name, district and city', () {
    final rules = {
      'name': (PharmacyProfileRules.name, PharmacyProfileRules.maxNameLength),
      'district': (
        PharmacyProfileRules.district,
        PharmacyProfileRules.maxPlaceLength,
      ),
      'city': (PharmacyProfileRules.city, PharmacyProfileRules.maxPlaceLength),
    };

    rules.forEach((field, rule) {
      final (check, max) = rule;

      test('$field is required', () {
        expect(check(null), isNotNull);
        expect(check('   '), isNotNull);
      });

      test('$field accepts up to $max characters', () {
        expect(check(' Kigali '), isNull);
        expect(check('a' * max), isNull);
        expect(check('a' * (max + 1)), isNotNull);
      });
    });
  });

  group('phone', () {
    test('is optional', () {
      expect(PharmacyProfileRules.phone(null), isNull);
      expect(PharmacyProfileRules.phone('  '), isNull);
    });

    test('accepts local and international numbers', () {
      expect(PharmacyProfileRules.phone('0788123456'), isNull);
      expect(PharmacyProfileRules.phone('+250 788 123 456'), isNull);
      expect(PharmacyProfileRules.phone('(078) 812-3456'), isNull);
    });

    test('refuses letters and a + in the middle', () {
      expect(PharmacyProfileRules.phone('0788 ABC 456'), isNotNull);
      expect(PharmacyProfileRules.phone('0788+123456'), isNotNull);
    });

    test('needs 9 to 15 digits', () {
      expect(PharmacyProfileRules.phone('12345678'), isNotNull);
      expect(PharmacyProfileRules.phone('123456789'), isNull);
      expect(PharmacyProfileRules.phone('1' * 15), isNull);
      expect(PharmacyProfileRules.phone('1' * 16), isNotNull);
    });
  });

  group('address', () {
    test('is optional', () {
      expect(PharmacyProfileRules.address(null), isNull);
      expect(PharmacyProfileRules.address(''), isNull);
    });

    test('accepts up to the maximum length', () {
      const max = PharmacyProfileRules.maxAddressLength;
      expect(PharmacyProfileRules.address('a' * max), isNull);
      expect(PharmacyProfileRules.address('a' * (max + 1)), isNotNull);
    });
  });
}
