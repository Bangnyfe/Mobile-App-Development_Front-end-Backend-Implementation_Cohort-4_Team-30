import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:team30_app/core/router/route_paths.dart';
import 'package:team30_app/core/theme/app_theme.dart';
import 'package:team30_app/features/pos/domain/entities/payment_method.dart';
import 'package:team30_app/features/pos/domain/entities/sale_receipt.dart';
import 'package:team30_app/features/pos/presentation/cubit/cart_cubit.dart';
import 'package:team30_app/features/pos/presentation/pages/receipt_page.dart';

import 'pos_page_test_helpers.dart';

void main() {
  late CartCubit cart;

  setUp(() => cart = seededCart());
  tearDown(() => cart.close());

  SaleReceipt receiptFor({
    String method = PaymentMethods.cash,
    int? cash = 10000,
    String servedBy = 'Aline Uwase',
  }) => SaleReceipt.fromCart(
    receiptNo: '260925-143205',
    createdAt: today,
    pharmacyName: 'Amani Pharmacy',
    pharmacyLocation: 'Nyarugenge, Kigali',
    servedBy: servedBy,
    paymentMethod: method,
    items: cart.state.items,
    cashReceived: cash,
  );

  /// Receipt as in the app, with Sell and Inventory one tap away.
  Future<void> pumpReceipt(WidgetTester tester, SaleReceipt receipt) async {
    final router = GoRouter(
      initialLocation: RoutePaths.sellReceipt,
      routes: [
        GoRoute(
          path: RoutePaths.sell,
          builder: (context, state) => const Scaffold(body: Text('Sell page')),
          routes: [
            GoRoute(
              path: 'receipt',
              builder: (context, state) => ReceiptPage(receipt: receipt),
            ),
          ],
        ),
        GoRoute(
          path: RoutePaths.stock,
          builder: (context, state) =>
              const Scaffold(body: Text('Inventory page')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cart,
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the sale, the cash and the change', (tester) async {
    await pumpReceipt(tester, receiptFor());

    expect(find.text('Sale complete'), findsOneWidget);
    expect(find.text('Stock updated in 2 batches'), findsOneWidget);
    expect(find.text('Amani Pharmacy'), findsOneWidget);
    expect(find.text('Nyarugenge, Kigali'), findsOneWidget);
    expect(find.text('Receipt #260925-143205'), findsOneWidget);
    expect(find.text('25 Sep 2026 · 14:32'), findsOneWidget);

    expect(find.text('Amoxicillin 500mg'), findsOneWidget);
    expect(find.text('2 × 2,500 · AX2407'), findsOneWidget);
    expect(find.text('5,000'), findsOneWidget);
    expect(find.text('Paracetamol 500mg'), findsOneWidget);
    expect(find.text('3 × 300 · PC2506'), findsOneWidget);

    expect(find.text('RWF 5,900'), findsOneWidget);
    expect(find.text('Cash received'), findsOneWidget);
    expect(find.text('10,000'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);
    expect(find.text('4,100'), findsOneWidget);
    expect(find.text('Served by Aline Uwase · Thank you'), findsOneWidget);
  });

  testWidgets('a Mobile Money sale shows how it was paid, with no change', (
    tester,
  ) async {
    await pumpReceipt(
      tester,
      receiptFor(method: PaymentMethods.mobileMoney, cash: null),
    );

    expect(find.text('Paid by'), findsOneWidget);
    expect(find.text('Mobile Money'), findsOneWidget);
    expect(find.text('Cash received'), findsNothing);
    expect(find.text('Change'), findsNothing);
  });

  testWidgets('says "1 batch" for a sale from a single batch', (tester) async {
    cart.removeItem(paracetamol.id);
    await pumpReceipt(tester, receiptFor(cash: 5000));

    expect(find.text('Stock updated in 1 batch'), findsOneWidget);
  });

  testWidgets('just thanks the customer when the seller is unknown', (
    tester,
  ) async {
    await pumpReceipt(tester, receiptFor(servedBy: ''));

    expect(find.text('Thank you'), findsOneWidget);
    expect(find.textContaining('Served by'), findsNothing);
  });

  testWidgets('New Sale empties the cart and returns to Sell', (tester) async {
    await pumpReceipt(tester, receiptFor());

    await tester.tap(find.text('New Sale'));
    await tester.pumpAndSettle();

    expect(cart.state.items, isEmpty);
    expect(find.text('Sell page'), findsOneWidget);
  });

  testWidgets('Inventory opens the Inventory tab', (tester) async {
    await pumpReceipt(tester, receiptFor());

    await tester.tap(find.text('Inventory'));
    await tester.pumpAndSettle();

    expect(find.text('Inventory page'), findsOneWidget);
  });

  testWidgets('fits a landscape phone without overflow', (tester) async {
    useLandscapePhone(tester);
    await pumpReceipt(tester, receiptFor());

    expect(tester.takeException(), isNull);
    expect(find.text('New Sale'), findsOneWidget);
  });
}
