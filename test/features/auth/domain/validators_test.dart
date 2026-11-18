import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/auth/domain/validators.dart';

void main() {
  group('AuthValidators.email', () {
    test('rejects an empty or blank value', () {
      expect(AuthValidators.email(null), 'Enter your email address.');
      expect(AuthValidators.email('   '), 'Enter your email address.');
    });

    test('rejects values that are not email addresses', () {
      for (final value in ['aline', 'aline@', 'aline@pharmacy', 'a b@x.rw']) {
        expect(AuthValidators.email(value), isNotNull, reason: value);
      }
    });

    test('accepts a valid address, ignoring surrounding spaces', () {
      expect(AuthValidators.email('aline@amanipharmacy.rw'), isNull);
      expect(AuthValidators.email('  aline@amanipharmacy.rw '), isNull);
    });
  });

  group('AuthValidators.newPassword', () {
    test('requires a value', () {
      expect(AuthValidators.newPassword(''), 'Choose a password.');
    });

    test('requires at least 8 characters', () {
      expect(
        AuthValidators.newPassword('abc123'),
        'Use at least 8 characters.',
      );
    });

    test('requires both a letter and a number', () {
      const message = 'Include at least one letter and one number.';
      expect(AuthValidators.newPassword('abcdefgh'), message);
      expect(AuthValidators.newPassword('12345678'), message);
    });

    test('accepts a strong password', () {
      expect(AuthValidators.newPassword('pharmacy2026'), isNull);
    });
  });

  group('AuthValidators.loginPassword', () {
    test('only checks that a password was typed', () {
      expect(AuthValidators.loginPassword(''), 'Enter your password.');
      expect(AuthValidators.loginPassword('short'), isNull);
    });
  });

  group('AuthValidators.confirmPassword', () {
    test('requires a value', () {
      expect(
        AuthValidators.confirmPassword('', 'pharmacy2026'),
        'Re-enter your password.',
      );
    });

    test('must match the password', () {
      expect(
        AuthValidators.confirmPassword('pharmacy2025', 'pharmacy2026'),
        'Passwords do not match.',
      );
      expect(
        AuthValidators.confirmPassword('pharmacy2026', 'pharmacy2026'),
        isNull,
      );
    });
  });

  group('AuthValidators.requiredField', () {
    test('names the missing field', () {
      expect(
        AuthValidators.requiredField(' ', 'the pharmacy name'),
        'Enter the pharmacy name.',
      );
      expect(
        AuthValidators.requiredField('Amani Pharmacy', 'the name'),
        isNull,
      );
    });
  });
}