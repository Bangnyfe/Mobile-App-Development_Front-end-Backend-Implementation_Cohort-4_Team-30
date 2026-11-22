import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:team30_app/core/router/route_paths.dart';
import 'package:team30_app/core/theme/app_theme.dart';
import 'package:team30_app/features/pos/data/fake_checkout_repository.dart';
import 'package:team30_app/features/pos/domain/entities/payment_method.dart';
import 'package:team30_app/features/pos/domain/entities/sale_receipt.dart';
import 'package:team30_app/features/pos/presentation/cubit/cart_cubit.dart';
import 'package:team30_app/features/pos/presentation/cubit/checkout_cubit.dart';
import 'package:team30_app/features/pos/presentation/cubit/payment_form_cubit.dart';
import 'package:team30_app/features/pos/presentation/pages/checkout_page.dart';
import 'package:team30_app/features/pos/presentation/pages/receipt_page.dart';
import 'package:team30_app/features/settings/data/fake_account_repository.dart';
import 'package:team30_app/features/settings/presentation/cubit/account_cubit.dart';

import 'pos_page_test_helpers.dart';

void main() {
  late CartCubit cart;
  late FakeCheckoutRepository repository;

  setUp(() {
    cart = seededCart();
    repository = FakeCheckoutRepository();
  });
  tearDown(() => cart.close());

  /// Checkout as in the app: the shared cart and account above the router,
  /// with Receipt reachable after a successful sale.
  Future<void> pumpCheckout(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: RoutePaths.sellCheckout,
      routes: [
        GoRoute(
          path: RoutePaths.sell,
          builder: (context, state) => const Scaffold(body: Text('Sell')),
          routes: [
            GoRoute(
              path: 'checkout',
              builder: (context, state) => MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => CheckoutCubit(repository)),
                  BlocProvider(create: (_) => PaymentFormCubit()),
                ],
                child: CheckoutPage(clock: () => today),
              ),
            ),
            GoRoute(
              path: 'receipt',
              builder: (context, state) =>
                  ReceiptPage(receipt: state.extra! as SaleReceipt),
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
          BlocProvider(
            create: (_) => AccountCubit(const FakeAccountRepository())..load(),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterCash(WidgetTester tester, String cash) async {
    await tester.enterText(find.byKey(const ValueKey('cash-received')), cash);
    await tester.pumpAndSettle();
  }

  Finder confirmFinder() => find.widgetWithText(FilledButton, 'Confirm sale');

  bool confirmEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(confirmFinder()).onPressed != null;

  String change(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const ValueKey('change-amount'))).data!;

  testWidgets('shows the amount due and cash selected by default', (
    tester,
  ) async {
    await pumpCheckout(tester);

    expect(find.text('RWF 5,900'), findsOneWidget);
    expect(find.text('2 products · 5 units'), findsOneWidget);
    expect(find.text('Cash received (RWF)'), findsOneWidget);
  });

  testWidgets('Confirm stays disabled until the cash covers the total', (
    tester,
  ) async {
    await pumpCheckout(tester);
    expect(confirmEnabled(tester), isFalse);

    await enterCash(tester, '5000');
    expect(confirmEnabled(tester), isFalse);
    expect(find.text('Not enough cash'), findsOneWidget);
    expect(change(tester), 'RWF 900 short');

    await enterCash(tester, '5900');
    expect(confirmEnabled(tester), isTrue);
    expect(change(tester), 'RWF 0');
  });

  testWidgets('the change row shows the change to give back', (tester) async {
    await pumpCheckout(tester);

    await enterCash(tester, '10000');

    expect(find.text('Change to give back'), findsOneWidget);
    expect(change(tester), 'RWF 4,100');
  });

  testWidgets('Mobile Money needs no cash and hides the cash field', (
    tester,
  ) async {
    await pumpCheckout(tester);

    await tester.tap(find.text(PaymentMethods.mobileMoney));
    await tester.pumpAndSettle();

    expect(find.text('Cash received (RWF)'), findsNothing);
    expect(confirmEnabled(tester), isTrue);
  });

  testWidgets('a failed checkout shows its message in a SnackBar', (
    tester,
  ) async {
    repository.failWith = 'Insufficient stock. Available: 1, Requested: 2.';
    await pumpCheckout(tester);

    await enterCash(tester, '10000');
    await tester.tap(confirmFinder());
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text('Insufficient stock. Available: 1, Requested: 2.'),
      ),
      findsOneWidget,
    );
    // Still on Checkout with the cart kept, so the sale can be retried.
    expect(find.text('Sale complete'), findsNothing);
    expect(cart.state.items, hasLength(2));
  });

  testWidgets('a confirmed sale opens its receipt and empties the cart', (
    tester,
  ) async {
    await pumpCheckout(tester);

    await enterCash(tester, '10000');
    await tester.tap(confirmFinder());
    await tester.pumpAndSettle();

    expect(repository.sales, hasLength(1));
    expect(repository.sales.values.single.cashReceived, 10000);
    // Who sold it, by uid and by name, from the signed-in account.
    expect(repository.sales.values.single.soldBy, 'u1');
    expect(repository.sales.values.single.soldByName, 'Aline Uwase');
    expect(cart.state.items, isEmpty);

    expect(find.text('Sale complete'), findsOneWidget);
    expect(find.text('Stock updated in 2 batches'), findsOneWidget);
    expect(find.text('Amani Pharmacy'), findsOneWidget);
    expect(find.text('Nyarugenge, Kigali'), findsOneWidget);
    expect(find.text('2 × 2,500 · AX2407'), findsOneWidget);
    expect(find.text('RWF 5,900'), findsOneWidget);
    expect(find.text('10,000'), findsOneWidget);
    expect(find.text('4,100'), findsOneWidget);
    expect(find.text('Served by Aline Uwase · Thank you'), findsOneWidget);
  });

  testWidgets('fits a landscape phone without overflow', (tester) async {
    useLandscapePhone(tester);
    await pumpCheckout(tester);

    expect(tester.takeException(), isNull);
    expect(confirmFinder(), findsOneWidget);
  });
}
