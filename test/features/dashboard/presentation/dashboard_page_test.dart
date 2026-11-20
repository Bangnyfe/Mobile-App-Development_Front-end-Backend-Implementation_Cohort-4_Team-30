import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/core/theme/app_theme.dart';
import 'package:team30_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:team30_app/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:team30_app/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:team30_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:team30_app/features/notifications/data/in_memory_seen_alerts_repository.dart';
import 'package:team30_app/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:team30_app/features/settings/domain/entities/app_settings.dart';

import '../../notifications/notifications_test_helpers.dart';
import '../dashboard_test_data.dart';

class _StubDashboardRepository implements DashboardRepository {
  _StubDashboardRepository(this._stream);

  final Stream<DashboardSummary> _stream;

  @override
  Stream<DashboardSummary> watchSummary() => _stream;
}

/// Pumps the dashboard on a phone-sized screen (360 x 800 logical pixels
/// in portrait by default) so the whole page is laid out.
Future<void> pumpDashboard(
  WidgetTester tester,
  Stream<DashboardSummary> stream, {
  Size physicalSize = const Size(1080, 2400),
}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) =>
                DashboardCubit(_StubDashboardRepository(stream))..start(),
          ),
          // For the bell; no alerts, so no badge.
          BlocProvider(
            create: (_) => NotificationsCubit(
              stockRepository: FixedStockAlertsRepository(const []),
              seenRepository: InMemorySeenAlertsRepository(),
              initialSettings: const AppSettings(),
              settingsChanges: const Stream.empty(),
            )..start(),
          ),
        ],
        // Friday 25 Sep 2026, 14:40 -> "Good afternoon".
        child: DashboardPage(clock: () => DateTime(2026, 9, 25, 14, 40)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the summary from the cubit', (tester) async {
    await pumpDashboard(tester, Stream.value(buildSummary()));

    expect(find.text('Friday, 25 Sep'), findsOneWidget);
    expect(find.text('Good afternoon, Aline'), findsOneWidget);
    expect(find.text('RWF 284,500'), findsOneWidget);
    expect(find.text('+12%'), findsOneWidget);
    expect(find.text('412'), findsOneWidget);
    expect(find.text('Expiring in 30 days'), findsOneWidget);
    expect(find.text('Sale #0142'), findsOneWidget);
    expect(find.text('14:32 · 3 items · Cash'), findsOneWidget);
  });

  testWidgets('shows an empty message when there are no sales', (tester) async {
    await pumpDashboard(tester, Stream.value(buildSummary(recentSales: [])));

    expect(find.text('No sales yet today.'), findsOneWidget);
  });

  testWidgets('shows an error with a retry button', (tester) async {
    await pumpDashboard(tester, Stream.error(Exception('offline')));

    expect(
      find.text('Could not load the dashboard. Try again.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('fits in landscape without overflowing', (tester) async {
    await pumpDashboard(
      tester,
      Stream.value(buildSummary()),
      physicalSize: const Size(2400, 1080),
    );

    expect(tester.takeException(), isNull);
  });
}
