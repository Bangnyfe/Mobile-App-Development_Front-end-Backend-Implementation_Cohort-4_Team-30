import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/reports/presentation/cubit/stock_reports_cubit.dart';
import 'package:team30_app/features/reports/presentation/pages/expiry_waste_report_page.dart';
import 'package:team30_app/features/reports/presentation/pages/inventory_report_page.dart';
import 'package:team30_app/features/stock_removal/data/fake_stock_removal_repository.dart';

void main() {
  final now = DateTime(2026, 11, 22, 9, 30);

  Future<void> pumpReport(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => StockReportsCubit(
            FakeStockRemovalRepository(clock: () => now),
            clock: () => now,
          )..load(),
          child: page,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Inventory report shows stock value, this month and removals', (
    tester,
  ) async {
    await pumpReport(tester, const InventoryReportPage());

    expect(find.text('RWF 686,900'), findsOneWidget);
    expect(find.text('5 products in stock'), findsOneWidget);
    expect(find.text('12 units · RWF 20,400'), findsOneWidget);
    expect(find.text('2 removals'), findsOneWidget);
    expect(find.text('Ibuprofen 400mg'), findsOneWidget);
    expect(find.text('Damaged'), findsOneWidget);
  });

  testWidgets('Expiry and waste switches period and offers Remove stock', (
    tester,
  ) async {
    await pumpReport(tester, const ExpiryWasteReportPage());

    expect(find.text('RWF 6,400'), findsOneWidget);
    expect(find.text('1 batch removed'), findsOneWidget);
    expect(find.text('Needs to be removed'), findsOneWidget);
    expect(find.text('Remove stock'), findsNWidgets(4));

    await tester.tap(find.text('3 months'));
    await tester.pumpAndSettle();

    expect(find.text('RWF 17,400'), findsOneWidget);
    expect(find.text('2 batches removed'), findsOneWidget);
  });
}
