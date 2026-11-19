import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/sales/data/fake_sales_repository.dart';

void main() {
  final repository = FakeSalesRepository(
    clock: () => DateTime(2026, 11, 19, 15),
  );

  test('lists sales newest first', () async {
    final sales = await repository.watchSales().first;
    final times = sales.map((sale) => sale.createdAt).toList();

    expect(sales, isNotEmpty);
    expect(times, [...times]..sort((a, b) => b.compareTo(a)));
  });

  test('every sample total matches its lines', () async {
    final sales = await repository.watchSales().first;

    for (final sale in sales) {
      final linesTotal = sale.lines.fold(0, (sum, l) => sum + l.lineTotal);
      expect(linesTotal, sale.total, reason: 'receipt ${sale.receiptNo}');
      expect(sale.cashReceived - sale.change, sale.total);
    }
  });

  test('respects the limit', () async {
    expect(await repository.watchSales(limit: 2).first, hasLength(2));
  });

  test('finds a sale by ID and returns null for an unknown one', () async {
    expect((await repository.getSale('sale-0141'))?.receiptNo, '0141');
    expect(await repository.getSale('missing'), isNull);
  });
}
