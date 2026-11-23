import 'package:equatable/equatable.dart';

import 'cart_item.dart';
import 'payment_method.dart';

/// What the Receipt screen shows for a confirmed sale.
///
/// `CheckoutState.success` only carries the receipt number, so Checkout
/// builds this from the cart and payment it just confirmed.
class SaleReceipt extends Equatable {
  const SaleReceipt({
    required this.receiptNo,
    required this.createdAt,
    required this.pharmacyName,
    required this.pharmacyLocation,
    required this.servedBy,
    required this.paymentMethod,
    required this.lines,
    required this.cashReceived,
    required this.change,
    required this.batchesUpdated,
  });

  /// The receipt for [items] paid with [paymentMethod]. Only cash sales take
  /// [cashReceived]; other methods are paid in full with no change, as
  /// `CheckoutCubit` records them.
  factory SaleReceipt.fromCart({
    required String receiptNo,
    required DateTime createdAt,
    required String pharmacyName,
    required String pharmacyLocation,
    required String servedBy,
    required String paymentMethod,
    required List<CartItem> items,
    int? cashReceived,
  }) {
    final total = items.fold<int>(0, (sum, item) => sum + item.lineTotal);
    final isCash = paymentMethod == PaymentMethods.cash;
    final paid = isCash ? (cashReceived ?? total) : total;
    final batchIds = {
      for (final item in items)
        for (final allocation in item.allocations) allocation.batchId,
    };
    return SaleReceipt(
      receiptNo: receiptNo,
      createdAt: createdAt,
      pharmacyName: pharmacyName,
      pharmacyLocation: pharmacyLocation,
      servedBy: servedBy,
      paymentMethod: paymentMethod,
      lines: [
        for (final item in items)
          SaleReceiptLine(
            productName: item.product.name,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            batchNumbers: item.allocations.isEmpty
                ? [item.batch.batchNumber]
                : [for (final a in item.allocations) a.batchNumber],
          ),
      ],
      cashReceived: paid,
      change: paid - total,
      batchesUpdated: batchIds.length,
    );
  }

  final String receiptNo;
  final DateTime createdAt;
  final String pharmacyName;

  /// e.g. "Nyarugenge, Kigali".
  final String pharmacyLocation;

  /// Name of the person who made the sale.
  final String servedBy;

  final String paymentMethod;
  final List<SaleReceiptLine> lines;
  final int cashReceived;
  final int change;

  /// How many batches the sale took stock from.
  final int batchesUpdated;

  int get total => lines.fold(0, (sum, line) => sum + line.lineTotal);

  bool get isCash => paymentMethod == PaymentMethods.cash;

  @override
  List<Object?> get props => [
    receiptNo,
    createdAt,
    pharmacyName,
    pharmacyLocation,
    servedBy,
    paymentMethod,
    lines,
    cashReceived,
    change,
    batchesUpdated,
  ];
}

/// One product on a receipt.
class SaleReceiptLine extends Equatable {
  const SaleReceiptLine({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.batchNumbers,
  });

  final String productName;
  final int quantity;
  final int unitPrice;

  /// The batches the units came from, earliest expiry first.
  final List<String> batchNumbers;

  int get lineTotal => quantity * unitPrice;

  @override
  List<Object?> get props => [productName, quantity, unitPrice, batchNumbers];
}
