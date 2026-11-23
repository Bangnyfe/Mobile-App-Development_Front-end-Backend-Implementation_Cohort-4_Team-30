/// Checks for the Edit pharmacy profile form. Each returns an error message
/// to show under the field, or null when the value is fine.
abstract final class PharmacyProfileRules {
  static const maxNameLength = 60;
  static const maxPlaceLength = 40;
  static const maxAddressLength = 120;

  static String? name(String? value) => _required(
    value,
    empty: 'Enter the pharmacy name',
    max: maxNameLength,
    tooLong: 'Keep the name under $maxNameLength characters',
  );

  static String? district(String? value) => _required(
    value,
    empty: 'Enter the district',
    max: maxPlaceLength,
    tooLong: 'Keep the district under $maxPlaceLength characters',
  );

  static String? city(String? value) => _required(
    value,
    empty: 'Enter the city',
    max: maxPlaceLength,
    tooLong: 'Keep the city under $maxPlaceLength characters',
  );

  /// Optional. Digits with spaces, dashes, brackets and a leading +, 9 to
  /// 15 digits in all (e.g. "+250 788 123 456" or "0788123456").
  static String? phone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!RegExp(r'^\+?[0-9 ()-]+$').hasMatch(text)) {
      return 'Use digits only, with an optional + at the start';
    }
    final digits = text.replaceAll(RegExp('[^0-9]'), '').length;
    if (digits < 9 || digits > 15) {
      return 'Enter a phone number of 9 to 15 digits';
    }
    return null;
  }

  /// Optional.
  static String? address(String? value) {
    final text = value?.trim() ?? '';
    if (text.length > maxAddressLength) {
      return 'Keep the address under $maxAddressLength characters';
    }
    return null;
  }

  static String? _required(
    String? value, {
    required String empty,
    required int max,
    required String tooLong,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return empty;
    if (text.length > max) return tooLong;
    return null;
  }
}
