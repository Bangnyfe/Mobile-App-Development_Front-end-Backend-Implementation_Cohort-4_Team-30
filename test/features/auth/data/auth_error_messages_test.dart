import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/auth/data/auth_error_messages.dart';

void main() {
  group('authErrorMessage', () {
    test('gives one message for any wrong email or password', () {
      final messages = {
        authErrorMessage('invalid-credential'),
        authErrorMessage('wrong-password'),
        authErrorMessage('user-not-found'),
      };
      expect(messages, hasLength(1));
      expect(messages.single, contains('do not match'));
    });

    test('explains common registration errors', () {
      expect(authErrorMessage('email-already-in-use'), contains('Sign in'));
      expect(authErrorMessage('weak-password'), contains('8 characters'));
      expect(authErrorMessage('invalid-email'), contains('not valid'));
    });

    test('explains connection and rate-limit errors', () {
      expect(
        authErrorMessage('network-request-failed'),
        contains('internet connection'),
      );
      expect(authErrorMessage('too-many-requests'), contains('Wait'));
    });

    test('falls back to a polite generic message for unknown codes', () {
      expect(
        authErrorMessage('some-new-code'),
        'Something went wrong. Please try again.',
      );
    });
  });
}