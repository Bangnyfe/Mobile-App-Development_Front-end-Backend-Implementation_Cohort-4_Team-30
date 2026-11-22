import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team30_app/core/router/route_paths.dart';
import 'package:team30_app/core/theme/app_theme.dart';
import 'package:team30_app/features/pos/domain/entities/pos_batch.dart';
import 'package:team30_app/features/pos/presentation/cubit/batch_pick_cubit.dart';
import 'package:team30_app/features/pos/presentation/cubit/cart_cubit.dart';
import 'package:team30_app/features/pos/presentation/pages/product_found_page.dart';
import 'package:team30_app/features/scanner/domain/entities/found_product.dart';
import 'package:team30_app/features/settings/data/shared_prefs_settings_repository.dart';
import 'package:team30_app/features/settings/presentation/cubit/settings_cubit.dart';

import 'pos_page_test_helpers.dart';

void main() {
  /// In date: 29 months past [today] (25 Sep 2026).
  final later = PosBatch(
    id: 'b-ax2503',
    batchNumber: 'AX2503',
    expiryDate: DateTime(2029, 3, 3),
    quantity: 60,
  );
  final expired = PosBatch(
    id: 'b-old',
    batchNumber: 'OLD1',
    expiryDate: DateTime(2026, 9, 1),
    quantity: 30,
  );

  late CartCubit cart;

  setUp(() => cart = CartCubit(clock: () => today));
  tearDown(() => cart.close());

  FoundProduct amoxicillinWith(List<PosBatch> batches) => FoundProduct(
    product: amoxicillin,
    details: 'Capsules · box of 21',
    batches: batches,
  );

  /// Product found as in the app, with Cart one route away.
  Future<void> pumpFound(WidgetTester tester, FoundProduct found) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsCubit(
      SharedPrefsSettingsRepository(await SharedPreferences.getInstance()),
    );
    addTearDown(settings.close);

    final router = GoRouter(
      initialLocation: RoutePaths.sellProduct,
      routes: [
        GoRoute(
          path: RoutePaths.sell,
          builder: (context, state) => const Scaffold(body: Text('Sell')),
          routes: [
            GoRoute(
              path: 'product',
              builder: (context, state) => BlocProvider(
                create: (context) => BatchPickCubit(
                  batches: found.batches,
                  today: today,
                  cart: cart.state.items,
                ),
                child: ProductFoundPage(found: found, clock: () => today),
              ),
            ),
            GoRoute(
              path: 'cart',
              builder: (context, state) =>
                  const Scaffold(body: Text('Cart page')),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: cart),
          BlocProvider.value(value: settings),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder addButton() => find.byWidgetPredicate(
    (widget) =>
        widget is FilledButton &&
        widget.child is Text &&
        (widget.child! as Text).data!.startsWith('Add to cart'),
  );

  bool addEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(addButton()).onPressed != null;

  String stockNote(String from, String to, String batch) =>
      'Stock will drop from $from to $to in batch $batch when the sale is '
      'confirmed.';

  testWidgets('shows the product and suggests the earliest-expiry batch', (
    tester,
  ) async {
    await pumpFound(tester, amoxicillinWith([later, amoxBatch, expired]));

    expect(find.text('Product found'), findsOneWidget);
    expect(find.text('Amoxicillin 500mg'), findsOneWidget);
    expect(find.text('Capsules · box of 21'), findsOneWidget);
    expect(find.text('Barcode 6001234567895'), findsOneWidget);
    expect(find.text('Earliest expiry suggested'), findsOneWidget);

    // Only sellable batches are offered: the expired one is left out.
    expect(find.text('AX2407'), findsOneWidget);
    expect(find.text('AX2503'), findsOneWidget);
    expect(find.text('OLD1'), findsNothing);
    expect(find.text('19 days left'), findsOneWidget);
    expect(find.text('29 months'), findsOneWidget);
    expect(find.text('Expires 14 Oct 2026 · 18 in stock'), findsOneWidget);

    expect(find.text(stockNote('18', '17', 'AX2407')), findsOneWidget);
    expect(find.text('Add to cart · RWF 2,500'), findsOneWidget);
  });

  testWidgets('the stepper updates the note and the button total', (
    tester,
  ) async {
    await pumpFound(tester, amoxicillinWith([amoxBatch]));

    await tester.tap(find.byTooltip('One more'));
    await tester.pumpAndSettle();

    expect(find.text(stockNote('18', '16', 'AX2407')), findsOneWidget);
    expect(find.text('Add to cart · RWF 5,000'), findsOneWidget);
  });

  testWidgets('the quantity stops at the units in the chosen batch', (
    tester,
  ) async {
    await pumpFound(tester, amoxicillinWith([amoxBatch.copyWith(quantity: 2)]));

    await tester.tap(find.byTooltip('One more'));
    await tester.pumpAndSettle();

    final plus = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.add),
    );
    expect(plus.onPressed, isNull);
    expect(find.text(stockNote('2', '0', 'AX2407')), findsOneWidget);
  });

  testWidgets('choosing another batch moves the note to that batch', (
    tester,
  ) async {
    await pumpFound(tester, amoxicillinWith([later, amoxBatch]));

    await tester.tap(find.text('AX2503'));
    await tester.pumpAndSettle();

    expect(find.text(stockNote('60', '59', 'AX2503')), findsOneWidget);
  });

  testWidgets('Add to cart sells from the chosen batch and opens the cart', (
    tester,
  ) async {
    await pumpFound(tester, amoxicillinWith([later, amoxBatch]));

    await tester.tap(find.text('AX2503'));
    await tester.tap(find.byTooltip('One more'));
    await tester.pumpAndSettle();
    await tester.tap(addButton());
    await tester.pumpAndSettle();

    final line = cart.state.items.single;
    expect(line.product, amoxicillin);
    expect(line.quantity, 2);
    expect(line.allocations.single.batchNumber, 'AX2503');
    expect(find.text('Cart page'), findsOneWidget);
  });

  testWidgets('a batch already all in the cart cannot be added again', (
    tester,
  ) async {
    cart.addItem(product: amoxicillin, batches: [amoxBatch], quantity: 18);
    await pumpFound(tester, amoxicillinWith([amoxBatch]));

    expect(
      find.text('All 18 units of batch AX2407 are already in the cart.'),
      findsOneWidget,
    );
    expect(addEnabled(tester), isFalse);
  });

  testWidgets('a product with nothing sellable cannot be added', (
    tester,
  ) async {
    await pumpFound(tester, amoxicillinWith([expired]));

    expect(
      find.text(
        'Nothing to sell: every batch of this product is expired or out of '
        'stock.',
      ),
      findsOneWidget,
    );
    expect(find.text('Quantity'), findsNothing);
    expect(addEnabled(tester), isFalse);
  });

  testWidgets('fits a landscape phone without overflow', (tester) async {
    useLandscapePhone(tester);
    await pumpFound(tester, amoxicillinWith([later, amoxBatch]));

    expect(tester.takeException(), isNull);
    expect(addButton(), findsOneWidget);
  });
}
