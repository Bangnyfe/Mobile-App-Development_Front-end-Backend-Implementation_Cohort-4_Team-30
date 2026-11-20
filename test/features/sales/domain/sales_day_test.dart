import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/sales/domain/entities/sales_day.dart';

import '../sales_test_helpers.dart';

void main() {
  test('groups sales by calendar day, newest first', () {
    final morning = buildSale(id: 'a', createdAt: DateTime(2026, 11, 19, 9));
    final evening = buildSale(id: 'b', createdAt: DateTime(2026, 11, 19, 21));
    final yesterday = buildSale(
      id: 'c',
      createdAt: DateTime(2026, 11, 18, 23, 59),
    );

    // Deliberately out of order.
    final days = groupSalesByDay([morning, yesterday, evening]);

    expect(days.map((day) => day.date), [
      DateTime(2026, 11, 19),
      DateTime(2026, 11, 18),
    ]);
    expect(days.first.sales, [evening, morning]);
    expect(days.last.sales, [yesterday]);
  });

  test('adds up each day\'s total and count', () {
    final days = groupSalesByDay([
      buildSale(id: 'a', createdAt: DateTime(2026, 11, 19, 9), total: 2500),
      buildSale(id: 'b', createdAt: DateTime(2026, 11, 19, 10), total: 6900),
    ]);

    expect(days.single.total, 9400);
    expect(days.single.saleCount, 2);
  });

  test('returns no days for no sales', () {
    expect(groupSalesByDay([]), isEmpty);
  });
}
