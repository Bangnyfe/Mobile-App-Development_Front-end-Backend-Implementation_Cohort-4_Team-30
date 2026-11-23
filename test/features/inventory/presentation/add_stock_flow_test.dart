import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team30_app/app.dart';
import 'package:team30_app/core/router/app_router.dart';
import 'package:team30_app/features/inventory/data/fake_inventory_repository.dart';
import 'package:team30_app/features/inventory/presentation/pages/add_stock_page.dart';
import 'package:team30_app/features/inventory/presentation/pages/inventory_page.dart';
import 'package:team30_app/features/inventory/presentation/pages/register_product_page.dart';
import 'package:team30_app/features/scanner/presentation/pages/scanner_page.dart';
import 'package:team30_app/features/settings/data/shared_prefs_settings_repository.dart';

import '../../scanner/scanner_test_helpers.dart';

/// Amoxicillin's barcode, as a GS1 DataMatrix: GTIN, expiry 30 Jun 2028
/// and batch NEW77.
const _amoxicillinDataMatrix =
    '010600100702345417280630'
    '10NEW77';

/// A valid barcode no sample product has.
const _newBarcode = '6001007078904';

void main() {
  late FakeInventoryRepository repository;
  late FakeCamera camera;

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
    camera = FakeCamera();
    await tester.pumpWidget(
      ScannerCameraScope(
        cameraBuilder: camera.build,
        child: PharmacyApp(
          router: createAppRouter(),
          settingsRepository: SharedPrefsSettingsRepository(
            await SharedPreferences.getInstance(),
          ),
          inventoryRepository: repository,
        ),
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

  Future<void> scan(WidgetTester tester, String raw) async {
    await tester.tap(find.text('Scan barcode'));
    await tester.pumpAndSettle();
    camera.see(raw);
    await tester.pumpAndSettle();
  }

  Future<void> fillAndSave(
    WidgetTester tester, {
    String quantity = '60',
    String cost = '2800',
  }) async {
    await tester.enterText(find.byKey(const Key('quantityField')), quantity);
    await tester.enterText(find.byKey(const Key('costPriceField')), cost);
    await tester.tap(find.text('Add to stock'));
    await tester.pumpAndSettle();
  }

  testWidgets('scanning a DataMatrix fills in the batch and adds it', (
    tester,
  ) async {
    usePhone(tester);
    await openStockTab(tester);

    await tester.tap(find.text('Add stock'));
    await tester.pumpAndSettle();
    expect(find.byType(AddStockPage), findsOneWidget);

    await scan(tester, _amoxicillinDataMatrix);
    expect(find.text('Amoxicillin 500mg'), findsOneWidget);
    expect(find.text('NEW77'), findsOneWidget);
    expect(find.text('30 Jun 2028'), findsOneWidget);

    await fillAndSave(tester);
    expect(find.text('Stock added'), findsOneWidget);
    expect(
      repository.batches.where((b) => b.batchNumber == 'NEW77').single.quantity,
      60,
    );

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(InventoryPage), findsOneWidget);
    expect(find.text('180 units'), findsOneWidget);
  });

  testWidgets('a new barcode is registered, then its stock added', (
    tester,
  ) async {
    usePhone(tester);
    await openStockTab(tester);
    await tester.tap(find.text('Add stock'));
    await tester.pumpAndSettle();

    await scan(tester, _newBarcode);
    expect(find.text('New product'), findsOneWidget);

    await tester.tap(find.text('Register new product'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterProductPage), findsOneWidget);
    expect(find.text(_newBarcode), findsOneWidget);

    await tester.enterText(find.byKey(const Key('nameField')), 'Zinc 20mg');
    await tester.enterText(find.byKey(const Key('priceField')), '300');
    await tester.tap(find.widgetWithText(FilledButton, 'Register product'));
    await tester.pumpAndSettle();

    // Back on Add stock with the new product.
    expect(find.byType(AddStockPage), findsOneWidget);
    expect(find.text('Zinc 20mg'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('batchNumberField')), 'ZN-1');
    await fillAndSave(tester, quantity: '100', cost: '150');
    expect(find.text('Choose the expiry date'), findsOneWidget);

    await tester.tap(find.byKey(const Key('expiryDateField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to stock'));
    await tester.pumpAndSettle();

    expect(find.text('Stock added'), findsOneWidget);
    final zinc = repository.products.singleWhere((p) => p.name == 'Zinc 20mg');
    expect(zinc.barcode, _newBarcode);
    expect(
      repository.batches.singleWhere((b) => b.productId == zinc.id).quantity,
      100,
    );
  });

  testWidgets('an expired DataMatrix batch is refused', (tester) async {
    usePhone(tester);
    await openStockTab(tester);
    await tester.tap(find.text('Add stock'));
    await tester.pumpAndSettle();

    // Expired 31 Jan 2020.
    await scan(
      tester,
      '010600100702345417200131'
      '10OLD1',
    );
    await fillAndSave(tester);

    expect(
      find.text("This batch has already expired. Don't add it to stock."),
      findsOneWidget,
    );
    expect(repository.batches.where((b) => b.batchNumber == 'OLD1'), isEmpty);
  });

  testWidgets('Add stock from Product details skips the scan', (tester) async {
    usePhone(tester);
    await openStockTab(tester);
    await tester.tap(find.text('Paracetamol 500mg'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Add stock'));
    await tester.pumpAndSettle();

    expect(find.byType(AddStockPage), findsOneWidget);
    expect(find.text('Paracetamol 500mg'), findsOneWidget);
    expect(find.byKey(const Key('batchNumberField')), findsOneWidget);
  });

  testWidgets('registering a taken barcode shows why', (tester) async {
    usePhone(tester);
    await openStockTab(tester);

    await tester.tap(find.byTooltip('Register product'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('barcodeField')),
      '6001007023454',
    );
    await tester.enterText(find.byKey(const Key('nameField')), 'Amoxil');
    await tester.enterText(find.byKey(const Key('priceField')), '4000');
    await tester.tap(find.widgetWithText(FilledButton, 'Register product'));
    await tester.pumpAndSettle();

    expect(
      find.text('A product with this barcode is already registered.'),
      findsOneWidget,
    );
    expect(find.byType(RegisterProductPage), findsOneWidget);
  });

  testWidgets('a bad barcode check digit is caught on the form', (
    tester,
  ) async {
    usePhone(tester);
    await openStockTab(tester);
    await tester.tap(find.byTooltip('Register product'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('barcodeField')),
      '6001007023455',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Register product'));
    await tester.pumpAndSettle();

    expect(
      find.text("That isn't a valid product barcode. Check the digits."),
      findsOneWidget,
    );
    expect(find.text('Enter the product name'), findsOneWidget);
  });

  testWidgets('a new category can be added while registering', (tester) async {
    usePhone(tester);
    await openStockTab(tester);
    await tester.tap(find.byTooltip('Register product'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('No category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ New category').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('newCategoryField')),
      'Vitamins',
    );
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(repository.categories.map((c) => c.name), contains('Vitamins'));
    expect(find.text('Vitamins'), findsOneWidget);
  });

  testWidgets('Add stock and Register product work in landscape', (
    tester,
  ) async {
    usePhone(tester, landscape: true);
    await openStockTab(tester);

    await tester.tap(find.text('Add stock'));
    await tester.pumpAndSettle();
    await scan(tester, _amoxicillinDataMatrix);
    expect(tester.takeException(), isNull);
    expect(find.text('Add to stock'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Register product'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(RegisterProductPage), findsOneWidget);
  });
}
