import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team30_app/features/reports/domain/report_period.dart';
import 'package:team30_app/features/reports/domain/stock_report.dart';
import 'package:team30_app/features/reports/presentation/cubit/stock_reports_cubit.dart';
import 'package:team30_app/features/stock_removal/data/fake_stock_removal_repository.dart';
import 'package:team30_app/features/stock_removal/domain/repositories/stock_removal_repository.dart';

class _MockRepository extends Mock implements StockRemovalRepository {}

void main() {
  final now = DateTime(2026, 11, 22, 9, 30);

  StockReportsCubit build() => StockReportsCubit(
    FakeStockRemovalRepository(clock: () => now),
    clock: () => now,
  );

  test('loads stock and removals for the Inventory report', () async {
    final cubit = build();
    await cubit.load();
    final state = cubit.state;

    expect(state.status, StockReportsStatus.ready);
    expect(state.productCount, 5);
    expect(state.stockValue, 686900);
    expect(state.removals, hasLength(6));
    expect(
      state.thisMonthTotals,
      const RemovalTotals(count: 2, units: 12, value: 20400),
    );
  });

  test('the period changes the Expiry and waste totals and chart', () async {
    final cubit = build();
    await cubit.load();

    expect(cubit.state.expiredRemovedTotals.value, 6400);
    expect(cubit.state.expiredByMonth, hasLength(1));

    cubit.selectPeriod(ReportPeriod.threeMonths);
    expect(cubit.state.expiredRemovedTotals.value, 6400 + 11000);
    expect(cubit.state.expiredByMonth, hasLength(3));

    cubit.selectPeriod(ReportPeriod.year);
    expect(cubit.state.expiredRemovedTotals.count, 3);
    expect(cubit.state.expiredByMonth, hasLength(12));
  });

  test('lists expired stock still on the shelf', () async {
    final cubit = build();
    await cubit.load();

    expect(cubit.state.expiredStillOnShelf.map((l) => l.batchNumber), [
      'MZ2308',
      'AMX-2309',
      'IB2209',
      'CS-118',
    ]);
    expect(cubit.state.expiredOnShelfValue, 15400 + 140000 + 4800 + 10800);
  });

  test('a load failure shows the repository message', () async {
    final repository = _MockRepository();
    when(() => repository.loadProducts())
        .thenThrow(const StockRemovalFailure('No connection to the server.'));
    final cubit = StockReportsCubit(repository, clock: () => now);

    await cubit.load();

    expect(cubit.state.status, StockReportsStatus.failure);
    expect(cubit.state.message, 'No connection to the server.');
  });
}
