import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/core/theme/app_theme.dart';
import 'package:team30_app/core/widgets/app_bottom_nav.dart';
import 'package:team30_app/core/widgets/status_chip.dart';

Future<void> pumpInApp(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

StatusTone toneOf(WidgetTester tester) =>
    tester.widget<StatusChip>(find.byType(StatusChip)).tone;

void main() {
  final today = DateTime(2026, 11, 18);

  group('StatusChip', () {
    testWidgets('expiry chip shows days left in the warning colour', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        StatusChip.expiry(
          expiryDate: DateTime(2026, 12, 7),
          today: today,
          alertDays: 90,
        ),
      );

      expect(find.text('19 days'), findsOneWidget);
      expect(toneOf(tester), StatusTone.warning);
    });

    testWidgets('expired batch uses the danger colour', (tester) async {
      await pumpInApp(
        tester,
        StatusChip.expiry(
          expiryDate: DateTime(2026, 11, 1),
          today: today,
          alertDays: 90,
        ),
      );

      expect(find.text('Expired'), findsOneWidget);
      expect(toneOf(tester), StatusTone.danger);
    });

    testWidgets('low stock chip', (tester) async {
      await pumpInApp(tester, const StatusChip.lowStock());

      expect(find.text('Low stock'), findsOneWidget);
      expect(toneOf(tester), StatusTone.warning);
    });
  });

  group('AppBottomNav cart badge', () {
    Widget nav({required int cartCount}) => AppBottomNav(
      currentIndex: 0,
      onTabSelected: (_) {},
      cartCount: cartCount,
    );

    testWidgets('shows the cart count on the Sell tab', (tester) async {
      await pumpInApp(tester, nav(cartCount: 3));

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('hides the badge when the cart is empty', (tester) async {
      await pumpInApp(tester, nav(cartCount: 0));

      expect(find.text('0'), findsNothing);
      final badges = tester.widgetList<Badge>(find.byType(Badge));
      expect(badges.every((badge) => !badge.isLabelVisible), isTrue);
    });
  });
}
