import 'package:intl/intl.dart';

/// IDs for a new sale, taken from the moment Confirm is tapped.
///
/// The sale ID is the Firestore document ID, so it must be unique; the
/// receipt number is what the customer sees. A gap-free receipt sequence
/// (#0141, #0142, ...) would need a counter in Firestore.
abstract final class SaleIds {
  static final _receipt = DateFormat('yyMMdd-HHmmss', 'en_US');

  /// e.g. "sale-1790000000000000".
  static String saleId(DateTime at) => 'sale-${at.microsecondsSinceEpoch}';

  /// e.g. "260925-143205" for 25 Sep 2026, 14:32:05.
  static String receiptNo(DateTime at) => _receipt.format(at);
}
