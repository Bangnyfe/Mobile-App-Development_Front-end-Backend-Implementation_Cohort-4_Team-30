import 'package:equatable/equatable.dart';

import '../../stock_removal/domain/entities/removable_product.dart';
import '../../stock_removal/domain/entities/removal_reason.dart';
import '../../stock_removal/domain/entities/stock_removal.dart';

// The numbers on the Inventory report and the Expiry and waste report.
// Pure functions of the stock and the removals, so they are unit-tested
// without any screen or database.

/// How much was removed: number of removals, units and value at cost.
class RemovalTotals extends Equatable {
  const RemovalTotals({
    required this.count,
    required this.units,
    required this.value,
  });

  static const zero = RemovalTotals(count: 0, units: 0, value: 0);

  final int count;
  final int units;

  /// RWF, at cost.
  final int value;

  @override
  List<Object?> get props => [count, units, value];
}

RemovalTotals totalsOf(Iterable<StockRemoval> removals) {
  var count = 0;
  var units = 0;
  var value = 0;
  for (final removal in removals) {
    count++;
    units += removal.quantity;
    value += removal.costValue;
  }
  return RemovalTotals(count: count, units: units, value: value);
}

/// Removals on or after [from].
List<StockRemoval> removalsSince(List<StockRemoval> removals, DateTime from) =>
    removals.where((removal) => !removal.createdAt.isBefore(from)).toList();

/// Value of every unit on the shelf, at what the pharmacy paid for it.
int stockValueAtCost(List<RemovableProduct> products) {
  var value = 0;
  for (final product in products) {
    for (final batch in product.batches) {
      value += batch.costOf(batch.quantity);
    }
  }
  return value;
}

/// A batch past its expiry date that still has units on the shelf.
class ExpiredBatchLine extends Equatable {
  const ExpiredBatchLine({
    required this.productId,
    required this.productName,
    required this.batchId,
    required this.batchNumber,
    required this.expiryDate,
    required this.units,
    required this.value,
  });

  final String productId;
  final String productName;
  final String batchId;
  final String batchNumber;
  final DateTime expiryDate;
  final int units;

  /// RWF, at cost.
  final int value;

  @override
  List<Object?> get props => [
    productId,
    productName,
    batchId,
    batchNumber,
    expiryDate,
    units,
    value,
  ];
}

/// Expired batches still on the shelf, longest expired first.
List<ExpiredBatchLine> expiredOnShelf(
  List<RemovableProduct> products,
  DateTime today,
) {
  final lines = [
    for (final product in products)
      for (final batch in product.batches)
        if (batch.quantity > 0 && batch.isExpiredOn(today))
          ExpiredBatchLine(
            productId: product.id,
            productName: product.name,
            batchId: batch.id,
            batchNumber: batch.batchNumber,
            expiryDate: batch.expiryDate,
            units: batch.quantity,
            value: batch.costOf(batch.quantity),
          ),
  ];
  return lines..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
}

/// Value of expired stock removed in one calendar month.
class MonthTotal extends Equatable {
  const MonthTotal({required this.month, required this.value});

  /// Midnight on the 1st of the month.
  final DateTime month;

  /// RWF, at cost.
  final int value;

  @override
  List<Object?> get props => [month, value];
}

/// Expired stock removed per month, oldest month first, for the last
/// [months] calendar months including the current one. Months with no
/// removals are included with 0, so the chart has no gaps.
List<MonthTotal> expiredValueByMonth(
  List<StockRemoval> removals, {
  required DateTime today,
  required int months,
}) {
  final totals = <DateTime, int>{
    for (var i = months - 1; i >= 0; i--)
      DateTime(today.year, today.month - i): 0,
  };
  for (final removal in removals) {
    if (removal.reason != RemovalReason.expired) continue;
    final month = DateTime(removal.createdAt.year, removal.createdAt.month);
    if (totals.containsKey(month)) {
      totals[month] = totals[month]! + removal.costValue;
    }
  }
  return [
    for (final entry in totals.entries)
      MonthTotal(month: entry.key, value: entry.value),
  ];
}
