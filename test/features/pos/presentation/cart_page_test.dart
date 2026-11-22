import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/core/theme/app_theme.dart';
import 'package:team30_app/features/pos/presentation/cubit/cart_cubit.dart';
import 'package:team30_app/features/pos/presentation/pages/cart_page.dart';

import 'pos_page_test_helpers.dart';

void main() {
  late CartCubit cart;

  setUp(() => cart = seededCart());
  tearDown(() => cart.close());

  Future<void> pumpCart(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider.value(
        value: cart,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: CartPage(clock: () => today),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String total(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const ValueKey('cart-total'))).data!;

  Finder inLine(String productId, Finder finder) => find.descendant(
    of: find.byKey(ValueKey('cart-line-$productId')),
    matching: finder,
  );

  FilledButton checkoutButton(WidgetTester tester) => tester
      .widget<FilledButton>(find.widgetWithText(FilledButton, 'Checkout'));

  testWidgets('shows the item count, each line and the total', (tester) async {
    await pumpCart(tester);

    expect(find.text('Cart · 2 items'), findsOneWidget);
    expect(find.text('Amoxicillin 500mg'), findsOneWidget);
    expect(find.text('Batch AX2407 · exp 14 Oct 2026'), findsOneWidget);
    expect(find.text('RWF 2,500 each'), findsOneWidget);
    expect(inLine('amox', find.text('5,000')), findsOneWidget);
    expect(find.text('Subtotal (5 units)'), findsOneWidget);
    expect(total(tester), 'RWF 5,900');
    expect(checkoutButton(tester).onPressed, isNotNull);
  });

  testWidgets('the stepper changes the quantity and the total', (tester) async {
    await pumpCart(tester);

    await tester.tap(inLine('para', find.byTooltip('One more')));
    await tester.pumpAndSettle();

    expect(cart.state.items.last.quantity, 4);
    expect(total(tester), 'RWF 6,200');
    expect(find.text('Subtotal (6 units)'), findsOneWidget);
  });

  testWidgets('minus is disabled at one unit', (tester) async {
    cart.updateQuantity('amox', 1);
    await pumpCart(tester);

    final minus = tester.widget<IconButton>(
      inLine('amox', find.widgetWithIcon(IconButton, Icons.remove)),
    );
    expect(minus.onPressed, isNull);
  });

  testWidgets('removing a line updates the total and the count', (
    tester,
  ) async {
    await pumpCart(tester);

    await tester.tap(inLine('amox', find.text('Remove')));
    await tester.pumpAndSettle();

    expect(find.text('Amoxicillin 500mg'), findsNothing);
    expect(find.text('Cart · 1 item'), findsOneWidget);
    expect(total(tester), 'RWF 900');
    expect(find.text('Subtotal (3 units)'), findsOneWidget);
  });

  testWidgets('an empty cart shows the empty state and disables Checkout', (
    tester,
  ) async {
    await pumpCart(tester);

    await tester.tap(inLine('amox', find.text('Remove')));
    await tester.pumpAndSettle();
    await tester.tap(inLine('para', find.text('Remove')));
    await tester.pumpAndSettle();

    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(find.text('Cart · 0 items'), findsOneWidget);
    expect(total(tester), 'RWF 0');
    expect(checkoutButton(tester).onPressed, isNull);
  });

  testWidgets('fits a landscape phone without overflow', (tester) async {
    useLandscapePhone(tester);
    await pumpCart(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Checkout'), findsOneWidget);
  });
}
