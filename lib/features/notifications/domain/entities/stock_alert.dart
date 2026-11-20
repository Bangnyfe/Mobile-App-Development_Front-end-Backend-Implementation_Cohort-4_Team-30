import 'package:equatable/equatable.dart';

/// The kinds of alert, in the order the Notifications page shows them:
/// the most urgent first.
enum StockAlertType { expired, expiringSoon, lowStock }

/// One alert on the Notifications page.
class StockAlert extends Equatable {
  const StockAlert({
    required this.type,
    required this.productId,
    required this.productName,
    required this.quantity,
    this.batchId,
    this.batchNumber,
    this.expiryDate,
    this.reorderLevel,
  });

  final StockAlertType type;
  final String productId;
  final String productName;

  /// Units in the batch for expiry alerts, or the product's sellable units
  /// for low-stock alerts.
  final int quantity;

  /// Set for expiry alerts only.
  final String? batchId;
  final String? batchNumber;
  final DateTime? expiryDate;

  /// Set for low-stock alerts only: the level the product is at or below.
  final int? reorderLevel;

  /// Stable ID used to remember which alerts the user has already seen.
  ///
  /// It includes the type, so a batch that goes from "expiring soon" to
  /// "expired" counts as a new alert.
  String get id => switch (type) {
    StockAlertType.expired => 'expired:$batchId',
    StockAlertType.expiringSoon => 'expiring:$batchId',
    StockAlertType.lowStock => 'low:$productId',
  };

  bool get isOutOfStock => type == StockAlertType.lowStock && quantity <= 0;

  @override
  List<Object?> get props => [
    type,
    productId,
    productName,
    quantity,
    batchId,
    batchNumber,
    expiryDate,
    reorderLevel,
  ];
}
