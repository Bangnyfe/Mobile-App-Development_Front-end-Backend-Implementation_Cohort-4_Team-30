import 'package:equatable/equatable.dart';

import 'recent_sale.dart';

/// Everything the Home screen shows, in one snapshot.
///
/// Stock figures are summed from batch documents rather than stored on the
/// product, so they can never drift from the batches themselves.
class DashboardSummary extends Equatable {
  const DashboardSummary({
    required this.userFirstName,
    required this.todaySalesTotal,
    required this.todaySalesCount,
    required this.yesterdaySalesTotal,
    required this.productCount,
    required this.unitsInStock,
    required this.lowStockCount,
    required this.expiringWindowDays,
    required this.expiringBatchCount,
    required this.expiringCostValue,
    required this.expiredBatchCount,
    required this.recentSales,
  });

  /// First name from `users/{uid}.name`, used in the greeting.
  final String userFirstName;

  final int todaySalesTotal;
  final int todaySalesCount;
  final int yesterdaySalesTotal;

  final int productCount;
  final int unitsInStock;

  /// Products whose total units are at or below their reorder level.
  final int lowStockCount;

  /// The expiry alert period from Settings (e.g. 30 or 90 days).
  final int expiringWindowDays;

  /// Unexpired batches that expire within [expiringWindowDays].
  final int expiringBatchCount;

  /// Cost value (quantity x costPrice) of the expiring batches, in RWF.
  final int expiringCostValue;

  /// Batches past their expiry date that still have stock on the shelf.
  final int expiredBatchCount;

  /// Most recent sales first.
  final List<RecentSale> recentSales;

  /// Today's sales compared with yesterday's, as a percentage.
  ///
  /// Returns null when there were no sales yesterday, because any
  /// percentage would be meaningless (division by zero).
  double? get changeVsYesterday {
    if (yesterdaySalesTotal == 0) return null;
    return (todaySalesTotal - yesterdaySalesTotal) / yesterdaySalesTotal * 100;
  }

  @override
  List<Object?> get props => [
    userFirstName,
    todaySalesTotal,
    todaySalesCount,
    yesterdaySalesTotal,
    productCount,
    unitsInStock,
    lowStockCount,
    expiringWindowDays,
    expiringBatchCount,
    expiringCostValue,
    expiredBatchCount,
    recentSales,
  ];
}
