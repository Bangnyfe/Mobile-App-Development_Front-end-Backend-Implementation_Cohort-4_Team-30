import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team30_app/app.dart';
import 'package:team30_app/core/router/app_router.dart';
import 'package:team30_app/core/widgets/feature_placeholder_page.dart';
import 'package:team30_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:team30_app/features/pos/domain/entities/pos_batch.dart';
import 'package:team30_app/features/pos/domain/entities/pos_product.dart';
import 'package:team30_app/features/pos/presentation/cubit/cart_cubit.dart';
import 'package:team30_app/features/settings/data/shared_prefs_settings_repository.dart';
import 'package:team30_app/features/settings/presentation/pages/settings_page.dart';

/// Title of the placeholder tab page that is currently on screen.
String visiblePlaceholderTitle(WidgetTester tester) => tester
    .widget<FeaturePlaceholderPage>(find.byType(FeaturePlaceholderPage))
    .title;

Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Future<void> pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    PharmacyApp(
      router: createAppRouter(),
      settingsRepository: SharedPrefsSettingsRepository(
        await SharedPreferences.getInstance(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('app opens on the Home tab with the dashboard', (tester) async {
    await pumpApp(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(DashboardPage), findsOneWidget);
  });

  testWidgets('tapping each tab shows its page', (tester) async {
    await pumpApp(tester);

    const placeholderTabs = {
      'Sell': 'Sell',
      'Stock': 'Inventory',
      'Reports': 'Reports',
    };

    for (final MapEntry(key: label, value: title) in placeholderTabs.entries) {
      await tapTab(tester, label);
      expect(
        visiblePlaceholderTitle(tester),
        title,
        reason: 'after tapping $label',
      );
    }

    await tapTab(tester, 'Settings');
    expect(find.byType(SettingsPage), findsOneWidget);

    await tapTab(tester, 'Home');
    expect(find.byType(DashboardPage), findsOneWidget);
  });

  testWidgets('Quick scan opens the Sell tab', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Quick scan'));
    await tester.pumpAndSettle();

    expect(visiblePlaceholderTitle(tester), 'Sell');
  });

  testWidgets('Sell tab badge shows the units in the cart', (tester) async {
    await pumpApp(tester);

    Finder badge() => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byType(Badge),
    );
    expect(tester.widget<Badge>(badge()).isLabelVisible, isFalse);

    // The same CartCubit the Sell screens will use.
    final cart = BlocProvider.of<CartCubit>(
      tester.element(find.byType(NavigationBar)),
    );
    cart.addItem(
      product: const PosProduct(
        id: 'p1',
        barcode: '123',
        name: 'Paracetamol',
        sellingPrice: 500,
      ),
      batches: [
        PosBatch(
          id: 'b1',
          batchNumber: 'B001',
          expiryDate: DateTime(2099, 1, 1),
          quantity: 10,
        ),
      ],
      quantity: 3,
    );
    await tester.pumpAndSettle();

    expect(tester.widget<Badge>(badge()).isLabelVisible, isTrue);
    expect(
      find.descendant(of: badge(), matching: find.text('3')),
      findsOneWidget,
    );
  });
}
