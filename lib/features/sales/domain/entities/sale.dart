import 'package:equatable/equatable.dart';

/// A completed sale, read from `pharmacies/{id}/sales/{saleId}`.
///
/// The fields match what checkout saves, so Sales history and Sale details
/// show exactly what was sold, even if prices or products change later.
class Sale extends Equatable {
  const Sale({
    required this.id,
    required this.receiptNo,
    required this.createdAt,
    required this.soldBy,
    this.soldByName,
    required this.paymentMethod,
    required this.total,
    required this.cashReceived,
    required this.change,
    required this.lines,
  });

  final String id;
  final String receiptNo;
  final DateTime createdAt;

  /// The user ID of whoever made the sale.
  final String soldBy;

  /// Their name, copied onto the sale when it was made. Older sales may not
  /// have it, so use [sellerName] for display.
  final String? soldByName;

  /// "Cash", "Mobile Money" or "Card".
  final String paymentMethod;

  /// Sale total in RWF.
  final int total;

  /// What the customer handed over, in RWF. Equals [total] for Mobile Money
  /// and Card.
  final int cashReceived;

  /// Change given back, in RWF. 0 for Mobile Money and Card.
  final int change;

  /// One line per batch sold from. If one product's units came from two
  /// batches, it has two lines.
  final List<SaleLine> lines;

  static const cash = 'Cash';

  bool get isCash => paymentMethod == cash;

  /// The name to show for whoever made the sale.
  String get sellerName {
    final name = soldByName?.trim();
    return name == null || name.isEmpty ? soldBy : name;
  }

  /// Total units across all lines.
  int get itemCount => lines.fold(0, (sum, line) => sum + line.quantity);

  @override
  List<Object?> get props => [
    id,
    receiptNo,
    createdAt,
    soldBy,
    soldByName,
    paymentMethod,
    total,
    cashReceived,
    change,
    lines,
  ];
}

/// One line of a sale: some units of a product from one batch.
class SaleLine extends Equatable {
  const SaleLine({
    required this.productId,
    required this.batchId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  final String productId;
  final String batchId;

  /// The product's name when it was sold.
  final String productName;

  final int quantity;

  /// Price per unit in RWF when it was sold.
  final int unitPrice;

  int get lineTotal => quantity * unitPrice;

  @override
  List<Object?> get props => [
    productId,
    batchId,
    productName,
    quantity,
    unitPrice,
  ];
}
