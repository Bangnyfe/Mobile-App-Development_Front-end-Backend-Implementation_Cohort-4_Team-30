/// Checks for the product fields typed on Register product and Edit price.
///
/// Each returns the error to show under the field, or null when the value
/// is fine, so they plug straight into a `TextFormField.validator`.
abstract final class ProductFormRules {
  /// Prices above this are almost certainly a typo (an extra zero).
  static const maxSellingPrice = 10000000;
  static const maxReorderLevel = 100000;

  static String? name(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Enter the product name';
    if (name.length > 80) return 'Keep the name under 80 characters';
    return null;
  }

  /// Whole RWF, required.
  static String? sellingPrice(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter the selling price';
    final price = int.tryParse(text);
    if (price == null) return 'Enter whole RWF, without commas';
    if (price <= 0) return 'The price must be more than 0';
    if (price > maxSellingPrice) return 'That price looks too high';
    return null;
  }

  /// Optional: empty means "use the pharmacy default".
  static String? reorderLevel(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final level = int.tryParse(text);
    if (level == null) return 'Enter a whole number';
    if (level < 0) return "The level can't be negative";
    if (level > maxReorderLevel) return 'That level looks too high';
    return null;
  }

  /// The reorder level typed, or null for "use the pharmacy default".
  /// Only call once [reorderLevel] has accepted the value.
  static int? parseReorderLevel(String value) => int.tryParse(value.trim());
}
