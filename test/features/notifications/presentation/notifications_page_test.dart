import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/core/theme/app_theme.dart';
import 'package:team30_app/features/notifications/data/fake_stock_alerts_repository.dart';
import 'package:team30_app/features/notifications/data/in_memory_seen_alerts_repository.dart';
import 'package:team30_app/features/notifications/domain/repositories/stock_alerts_repository.dart';
import 'package:team30_app/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:team30_app/features/notifications/presentation/pages/notifications_page.dart';
import 'package:team30_app/features/settings/domain/entities/app_settings.dart';

import '../notifications_test_helpers.dart';

/// Opens the page from a home screen, so tests can also leave it with
/// back. Returns the cubit to check what was marked as seen.
Future<NotificationsCubit> pumpPage(
  WidgetTester tester, {
  StockAlertsRepository? stock,
  InMemorySeenAlertsRepository? seen,
  Size physicalSize = const Size(1080, 2400),
}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final cubit = NotificationsCubit(
    stockRepository: stock ?? FakeStockAlertsRepository(clock: () => testToday),
    seenRepository: seen ?? InMemorySeenAlertsRepository(),
    initialSettings: const AppSettings(),
    settingsChanges: const Stream.empty(),
    clock: () => testToday,
  )..start();
  addTearDown(cubit.close);

  await tester.pumpWidget(
    BlocProvider.value(
      value: cubit,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => NotificationsPage(clock: () => testToday),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return cubit;
}

Finder newDots() => find.byKey(const ValueKey('new-alert-dot'));

void main() {
  testWidgets('groups the sample alerts by kind, most urgent first', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Notifications'), findsOneWidget);
    final headers = ['EXPIRED', 'EXPIRING SOON', 'LOW STOCK'];
    final tops = [
      for (final header in headers) tester.getTopLeft(find.text(header)).dy,
    ];
    expect(tops, orderedEquals([...tops]..sort()));

    await tester.scrollUntilVisible(find.text('Ibuprofen 200mg'), 200);
    expect(find.text('Ibuprofen 200mg'), findsOneWidget);
  });

  testWidgets('shows the batch, units and date for each kind of alert', (
    tester,
  ) async {
    await pumpPage(tester);

    // Amoxicillin expired 12 days before 20 Nov 2026.
    expect(
      find.text('Batch AMX-2309 · 40 units · expired 8 Nov 2026'),
      findsOneWidget,
    );
    expect(find.text('Expired'), findsNWidgets(2));

    // Paracetamol expires in 19 days.
    expect(
      find.text('Batch PCM-2402 · 80 units · expires 9 Dec 2026'),
      findsOneWidget,
    );
    expect(find.text('19 days'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Ibuprofen 200mg'), 200);
    expect(find.text('12 units left · reorder at 25'), findsOneWidget);
    expect(find.text('No stock left · reorder at 40'), findsOneWidget);
    expect(find.text('Out of stock'), findsNWidgets(2));
    expect(find.text('Low stock'), findsNWidgets(2));
  });

  testWidgets('a batch expiring today says so', (tester) async {
    await pumpPage(
      tester,
      stock: FixedStockAlertsRepository([productExpiringIn(0)]),
    );

    expect(find.text('Expires today'), findsOneWidget);
  });

  testWidgets('marks only unseen alerts as new', (tester) async {
    await pumpPage(
      tester,
      stock: FixedStockAlertsRepository([
        productExpiringIn(-1, id: 'old', name: 'Old stock'),
        productExpiringIn(5, id: 'soon', name: 'Soon stock'),
      ]),
      seen: InMemorySeenAlertsRepository({'expired:b-old'}),
    );

    expect(newDots(), findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Soon stock'),
          matching: find.byType(MergeSemantics),
        ),
        matching: newDots(),
      ),
      findsOneWidget,
    );
  });

  testWidgets('leaving the page marks every alert as seen', (tester) async {
    final seen = InMemorySeenAlertsRepository();
    final cubit = await pumpPage(tester, seen: seen);
    expect(cubit.state.newCount, 8);
    // Still marked while the page is open.
    expect(newDots(), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(cubit.state.newCount, 0);
    expect(await seen.loadSeenIds(), hasLength(8));
  });

  testWidgets('shows All clear when nothing needs attention', (tester) async {
    await pumpPage(
      tester,
      stock: FixedStockAlertsRepository([productExpiringIn(300)]),
    );

    expect(find.text('All clear'), findsOneWidget);
  });

  testWidgets('shows an error with Try again', (tester) async {
    final stock = FixedStockAlertsRepository([
      productExpiringIn(3),
    ], fail: true);
    await pumpPage(tester, stock: stock);

    expect(find.text(NotificationsCubit.loadFailedMessage), findsOneWidget);

    stock.fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('3 days'), findsOneWidget);
  });

  testWidgets('fits in landscape without overflowing', (tester) async {
    await pumpPage(tester, physicalSize: const Size(2400, 1080));

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Ibuprofen 200mg'), 100);
    expect(find.text('Ibuprofen 200mg'), findsOneWidget);
  });
}
