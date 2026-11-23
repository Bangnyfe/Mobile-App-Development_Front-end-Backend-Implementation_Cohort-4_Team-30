import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team30_app/app.dart';
import 'package:team30_app/core/router/app_router.dart';
import 'package:team30_app/features/inventory/domain/entities/inventory_item.dart';
import 'package:team30_app/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:team30_app/features/notifications/data/inventory_stock_alerts_repository.dart';
import 'package:team30_app/features/notifications/presentation/pages/notifications_page.dart';
import 'package:team30_app/features/settings/data/shared_prefs_settings_repository.dart';

import '../../inventory/inventory_test_helpers.dart';

class _MockInventory extends Mock implements InventoryRepository {}

/// Batches far in the past or future, so the alerts don't depend on the
/// date the tests run.
InventoryItem _amoxicillin({int inDate = 100, int expired = 0}) => testItem(
  name: 'Amoxicillin 500mg',
  batches: [
    if (expired > 0)
      testBatch(id: 'b-old', quantity: expired, expiresInDays: -400),
    testBatch(id: 'b-new', quantity: inDate, expiresInDays: 3650),
  ],
);

String _bellTooltip(WidgetTester tester) => tester
    .widget<IconButton>(
      find.ancestor(of: find.byType(Badge), matching: find.byType(IconButton)),
    )
    .tooltip!;

void main() {
  testWidgets('the bell follows the stock as it is sold and expires', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});

    final stock = StreamController<List<InventoryItem>>.broadcast();
    addTearDown(stock.close);
    final inventory = _MockInventory();
    when(inventory.watchInventory).thenAnswer((_) => stock.stream);

    await tester.pumpWidget(
      PharmacyApp(
        router: createAppRouter(),
        settingsRepository: SharedPrefsSettingsRepository(
          await SharedPreferences.getInstance(),
        ),
        stockAlertsRepository: InventoryStockAlertsRepository(inventory),
      ),
    );
    stock.add([_amoxicillin()]);
    await tester.pumpAndSettle();

    // 100 units, in date: nothing to say.
    expect(_bellTooltip(tester), 'Notifications');

    // Sold down to 5, at or below the default threshold of 20.
    stock.add([_amoxicillin(inDate: 5)]);
    await tester.pumpAndSettle();
    expect(_bellTooltip(tester), 'Notifications, 1 new');

    // An expired batch turns up on the shelf too.
    stock.add([_amoxicillin(inDate: 5, expired: 3)]);
    await tester.pumpAndSettle();
    expect(_bellTooltip(tester), 'Notifications, 2 new');

    await tester.tap(find.byTooltip('Notifications, 2 new'));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsPage), findsOneWidget);
    expect(find.textContaining('Amoxicillin 500mg'), findsWidgets);
  });
}
