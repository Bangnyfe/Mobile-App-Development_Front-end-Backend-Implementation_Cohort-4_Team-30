/// Form validators for the auth screens.
abstract final class AuthValidators {
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static const minPasswordLength = 8;

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address.';
    if (!_emailPattern.hasMatch(email)) {
      return 'Enter a valid email address, like name@pharmacy.rw.';
    }
    return null;
  }

  /// For registration: at least 8 characters with a letter and a number.
  static String? newPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Choose a password.';
    if (password.length < minPasswordLength) {
      return 'Use at least $minPasswordLength characters.';
    }
    if (!password.contains(RegExp('[A-Za-z]')) ||
        !password.contains(RegExp('[0-9]'))) {
      return 'Include at least one letter and one number.';
    }
    return null;
  }

  static String? loginPassword(String? value) =>
      (value ?? '').isEmpty ? 'Enter your password.' : null;

  static String? confirmPassword(String? value, String password) {
    if ((value ?? '').isEmpty) return 'Re-enter your password.';
    if (value != password) return 'Passwords do not match.';
    return null;
  }

  static String? requiredField(String? value, String fieldName) =>
      (value?.trim() ?? '').isEmpty ? 'Enter $fieldName.' : null;
}