import '../../../core/utils/expiry_status.dart';
import '../../scanner/domain/gs1_parser.dart';

/// Checks for the fields typed on Register product and Add stock.
///
/// Each returns the error to show under the field, or null when the value
/// is fine, so they plug straight into a `TextFormField.validator`.
abstract final class StockFormRules {
  static const maxQuantity = 100000;
  static const maxCostPrice = 10000000;

  /// The barcode printed on the pack: 8, 12, 13 or 14 digits with a valid
  /// check digit, the same as the scanner accepts.
  static String? barcode(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Scan or type the barcode';
    if (normalizedBarcode(text) == null) {
      return "That isn't a valid product barcode. Check the digits.";
    }
    return null;
  }

  /// The barcode as products store it (13 digits for ordinary packs), so
  /// scans find it. Null when it isn't a valid barcode.
  static String? normalizedBarcode(String value) {
    final text = value.trim();
    if (!RegExp(r'^\d+$').hasMatch(text)) return null;
    return Gs1Parser.parse(text)?.gtin;
  }

  static String? batchNumber(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter the batch number from the pack';
    if (text.length > 30) return 'Keep the batch number under 30 characters';
    return null;
  }

  /// Units received, at least one.
  static String? quantity(String? value) {
    final quantity = int.tryParse(value?.trim() ?? '');
    if (quantity == null) return 'Enter the number of units';
    if (quantity < 1) return 'Enter at least 1 unit';
    if (quantity > maxQuantity) return 'That quantity looks too high';
    return null;
  }

  /// Whole RWF paid per unit.
  static String? costPrice(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter the cost per unit';
    final cost = int.tryParse(text);
    if (cost == null) return 'Enter whole RWF, without commas';
    if (cost < 0) return "The cost can't be negative";
    if (cost > maxCostPrice) return 'That cost looks too high';
    return null;
  }

  /// Expired stock must never be received; a batch expiring today is still
  /// allowed, matching the rest of the app.
  static String? expiryDate(DateTime? value, {required DateTime today}) {
    if (value == null) return 'Choose the expiry date';
    if (daysUntilExpiry(value, today: today) < 0) {
      return "This batch has already expired. Don't add it to stock.";
    }
    return null;
  }
}
