import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team30_app/app.dart';
import 'package:team30_app/core/router/app_router.dart';
import 'package:team30_app/features/inventory/data/fake_inventory_repository.dart';
import 'package:team30_app/features/inventory/presentation/cubit/product_details_cubit.dart';
import 'package:team30_app/features/inventory/presentation/pages/inventory_page.dart';
import 'package:team30_app/features/inventory/presentation/pages/product_details_page.dart';
import 'package:team30_app/features/settings/data/shared_prefs_settings_repository.dart';
import 'package:team30_app/features/settings/presentation/cubit/settings_cubit.dart';

/// The sample stock, relative to today: Metronidazole (9 sellable, expired
/// batch), Amoxicillin (120, expired batch), Cough syrup (only expired),
/// Ibuprofen (40, expired batch), Paracetamol (120) and Omeprazole (12,
/// expiring in 45 days). Default reorder level 20, alerts at 90 days.
void main() {
  late FakeInventoryRepository repository;

  void usePhone(WidgetTester tester, {bool landscape = false}) {
    tester.view.physicalSize = landscape
        ? const Size(2400, 1080)
        : const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
  }

  Future<void> openStockTab(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    repository = FakeInventoryRepository();
    await tester.pumpWidget(
      PharmacyApp(
        router: createAppRouter(),
        settingsRepository: SharedPrefsSettingsRepository(
          await SharedPreferences.getInstance(),
        ),
        inventoryRepository: repository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Stock'),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openProduct(WidgetTester tester, String name) async {
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
  }

  group('Inventory list', () {
    testWidgets('lists every product with units and filter counts', (
      tester,
    ) async {
      usePhone(tester);
      await openStockTab(tester);

      expect(find.byType(InventoryPage), findsOneWidget);
      expect(find.text('All (6)'), findsOneWidget);
      expect(find.text('Low stock (3)'), findsOneWidget);
      expect(find.text('Expiring soon (1)'), findsOneWidget);
      expect(find.text('Expired (4)'), findsOneWidget);
      expect(find.text('Paracetamol 500mg'), findsOneWidget);
      expect(find.text('9 units'), findsOneWidget);
      expect(find.text('Expired stock'), findsNWidgets(4));
    });

    testWidgets('filter chips and search narrow the list', (tester) async {
      usePhone(tester);
      await openStockTab(tester);

      await tester.tap(find.text('Low stock (3)'));
      await tester.pumpAndSettle();
      expect(find.text('Omeprazole 20mg'), findsOneWidget);
      expect(find.text('Paracetamol 500mg'), findsNothing);

      await tester.enterText(find.byKey(const Key('inventorySearch')), 'omep');
      await tester.pumpAndSettle();
      expect(find.text('Omeprazole 20mg'), findsOneWidget);
      expect(find.text('Metronidazole 400mg'), findsNothing);

      await tester.enterText(find.byKey(const Key('inventorySearch')), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('Nothing matches'), findsOneWidget);
    });

    testWidgets('shows a failure with Try again', (tester) async {
      usePhone(tester);
      SharedPreferences.setMockInitialValues({});
      repository = FakeInventoryRepository()..fail = true;
      await tester.pumpWidget(
        PharmacyApp(
          router: createAppRouter(),
          settingsRepository: SharedPrefsSettingsRepository(
            await SharedPreferences.getInstance(),
          ),
          inventoryRepository: repository,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stock'));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't load the inventory"), findsOneWidget);

      repository.fail = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('All (6)'), findsOneWidget);
    });

    testWidgets('works in landscape', (tester) async {
      usePhone(tester, landscape: true);
      await openStockTab(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('All (6)'), findsOneWidget);
    });
  });

  group('Product details', () {
    testWidgets('shows the price, stock and batches', (tester) async {
      usePhone(tester);
      await openStockTab(tester);
      await openProduct(tester, 'Amoxicillin 500mg');

      expect(find.byType(ProductDetailsPage), findsOneWidget);
      expect(find.text('RWF 4,500'), findsOneWidget);
      expect(find.text('120 units'), findsWidgets);
      expect(find.text('30 units'), findsOneWidget);
      expect(find.text('Batch AMX-2309'), findsOneWidget);
      expect(find.text('Batch AMX-2411'), findsOneWidget);
      expect(find.text('Sell first'), findsOneWidget);
    });

    testWidgets('the owner edits the price and reorder level', (tester) async {
      usePhone(tester);
      await openStockTab(tester);
      await openProduct(tester, 'Amoxicillin 500mg');

      await tester.tap(find.byTooltip('Product actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit price and reorder level'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('sellingPriceField')), '0');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('The price must be more than 0'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('sellingPriceField')),
        '5000',
      );
      await tester.enterText(find.byKey(const Key('reorderLevelField')), '');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('RWF 5,000'), findsOneWidget);
      expect(find.text('20 units (default)'), findsOneWidget);
    });

    testWidgets('the owner deletes a batch', (tester) async {
      usePhone(tester);
      await openStockTab(tester);
      await openProduct(tester, 'Amoxicillin 500mg');

      await tester.tap(find.byTooltip('Delete batch AMX-2309'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Batch AMX-2309'), findsNothing);
      expect(find.text('Batch AMX-2411'), findsOneWidget);
    });

    testWidgets('the owner deletes the product and returns to the list', (
      tester,
    ) async {
      usePhone(tester);
      await openStockTab(tester);
      await openProduct(tester, 'Amoxicillin 500mg');

      await tester.tap(find.byTooltip('Product actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete product'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.byType(InventoryPage), findsOneWidget);
      expect(find.text('All (5)'), findsOneWidget);
      expect(find.text('Amoxicillin 500mg'), findsNothing);
    });

    testWidgets('a pharmacist sees no edit or delete controls', (tester) async {
      usePhone(tester);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) =>
                    SettingsCubit(SharedPrefsSettingsRepository(prefs))..load(),
              ),
              BlocProvider(
                create: (_) => ProductDetailsCubit(
                  FakeInventoryRepository(),
                  'amoxicillin-500',
                )..start(),
              ),
            ],
            child: const ProductDetailsPage(canManage: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Batch AMX-2411'), findsOneWidget);
      expect(find.byTooltip('Product actions'), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('works in landscape', (tester) async {
      usePhone(tester, landscape: true);
      await openStockTab(tester);
      await openProduct(tester, 'Metronidazole 400mg');

      expect(tester.takeException(), isNull);
      expect(find.text('Batch MZ2410'), findsOneWidget);
    });
  });
}
