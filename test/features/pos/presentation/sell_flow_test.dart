import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team30_app/app.dart';
import 'package:team30_app/core/router/app_router.dart';
import 'package:team30_app/features/pos/presentation/pages/cart_page.dart';
import 'package:team30_app/features/pos/presentation/pages/product_found_page.dart';
import 'package:team30_app/features/pos/presentation/pages/sell_page.dart';
import 'package:team30_app/features/scanner/presentation/pages/scanner_page.dart';
import 'package:team30_app/features/settings/data/shared_prefs_settings_repository.dart';

import '../../scanner/scanner_test_helpers.dart';

/// Paracetamol 500mg in the sample products: RWF 700, one batch (PC2401).
const _paracetamol = '6001007045678';

/// A valid EAN-13 that no sample product has.
const _unknown = '4006381333931';

void main() {
  late FakeCamera camera;

  setUp(() => camera = FakeCamera());

  /// The whole app (sample data, no sign-in), with a fake camera, opened
  /// on the Sell tab.
  Future<void> openSell(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ScannerCameraScope(
        cameraBuilder: camera.build,
        child: PharmacyApp(
          router: createAppRouter(),
          settingsRepository: SharedPrefsSettingsRepository(
            await SharedPreferences.getInstance(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Sell'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SellPage), findsOneWidget);
  }

  /// The label on the badge inside [area], or null if the badge is hidden.
  String? badgeIn(WidgetTester tester, Finder area) {
    final badge = tester.widget<Badge>(
      find.descendant(of: area, matching: find.byType(Badge)),
    );
    if (!badge.isLabelVisible) return null;
    return (badge.label! as Text).data;
  }

  testWidgets('scan → Product found → Cart, without the bottom bar', (
    tester,
  ) async {
    await openSell(tester);

    camera.see(_paracetamol);
    await tester.pumpAndSettle();

    // Product found opens above the tabs, with the FEFO batch chosen.
    expect(find.byType(ProductFoundPage), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Paracetamol 500mg'), findsOneWidget);
    expect(find.text('PC2401'), findsOneWidget);
    expect(
      find.text(
        'Stock will drop from 120 to 119 in batch PC2401 when the sale is '
        'confirmed.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('One more'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Stock will drop from 120 to 118 in batch PC2401 when the sale is '
        'confirmed.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Add to cart · RWF 1,400'));
    await tester.pumpAndSettle();

    expect(find.byType(CartPage), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Cart · 1 item'), findsOneWidget);
    expect(find.text('RWF 1,400'), findsOneWidget);

    // Back from the cart returns to Sell, with the bottom bar again.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(SellPage), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Cart · RWF 1,400'), findsOneWidget);
  });

  testWidgets('both cart badges show the same number of units', (tester) async {
    await openSell(tester);
    expect(badgeIn(tester, find.byType(AppBar)), isNull);
    expect(badgeIn(tester, find.byType(NavigationBar)), isNull);

    camera.see(_paracetamol);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('One more'));
    await tester.tap(find.byTooltip('One more'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to cart · RWF 2,100'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 1 product, 3 units: both badges count units.
    expect(badgeIn(tester, find.byType(AppBar)), '3');
    expect(badgeIn(tester, find.byType(NavigationBar)), '3');
  });

  testWidgets('an unknown barcode shows a SnackBar and stays on Sell', (
    tester,
  ) async {
    await openSell(tester);

    camera.see(_unknown);
    await tester.pumpAndSettle();

    expect(find.text('No product with barcode $_unknown'), findsOneWidget);
    expect(find.byType(SellPage), findsOneWidget);
    expect(find.byType(ProductFoundPage), findsNothing);
  });

  testWidgets('typing a barcode in the search field finds the product', (
    tester,
  ) async {
    await openSell(tester);

    await tester.enterText(find.byType(TextField), _paracetamol);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.byType(ProductFoundPage), findsOneWidget);
  });

  testWidgets('searching by name explains that only barcodes work yet', (
    tester,
  ) async {
    await openSell(tester);

    await tester.enterText(find.byType(TextField), 'paracetamol');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text(SellPage.searchByNameMessage), findsOneWidget);
    expect(find.byType(ProductFoundPage), findsNothing);
  });
}
