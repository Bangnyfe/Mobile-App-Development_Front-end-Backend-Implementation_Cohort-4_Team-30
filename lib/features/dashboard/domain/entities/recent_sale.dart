import 'package:equatable/equatable.dart';

/// One row in the dashboard's "Recent transactions" list.
///
/// Built from a document in `pharmacies/{id}/sales`.
class RecentSale extends Equatable {
  const RecentSale({
    required this.saleId,
    required this.receiptNo,
    required this.createdAt,
    required this.itemCount,
    required this.paymentMethod,
    required this.total,
  });

  final String saleId;
  final String receiptNo;
  final DateTime createdAt;

  /// Total units across all line items in the sale.
  final int itemCount;

  /// "Cash", "Mobile Money" or "Card".
  final String paymentMethod;

  /// Sale total in RWF.
  final int total;

  @override
  List<Object?> get props => [
    saleId,
    receiptNo,
    createdAt,
    itemCount,
    paymentMethod,
    total,
  ];
}
