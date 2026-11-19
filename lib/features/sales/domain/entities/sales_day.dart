import 'package:equatable/equatable.dart';

import 'sale.dart';

/// One day's sales in Sales history, with the day's totals.
class SalesDay extends Equatable {
  const SalesDay({required this.date, required this.sales});

  /// Midnight at the start of the day.
  final DateTime date;

  /// Newest first.
  final List<Sale> sales;

  int get total => sales.fold(0, (sum, sale) => sum + sale.total);

  int get saleCount => sales.length;

  @override
  List<Object?> get props => [date, sales];
}

/// Groups [sales] by calendar day, newest day first and newest sale first
/// within each day.
List<SalesDay> groupSalesByDay(List<Sale> sales) {
  final byDay = <DateTime, List<Sale>>{};
  for (final sale in sales) {
    final at = sale.createdAt;
    final day = DateTime(at.year, at.month, at.day);
    byDay.putIfAbsent(day, () => []).add(sale);
  }

  final days = [
    for (final MapEntry(key: date, value: daySales) in byDay.entries)
      SalesDay(
        date: date,
        sales: daySales..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      ),
  ];
  return days..sort((a, b) => b.date.compareTo(a.date));
}
