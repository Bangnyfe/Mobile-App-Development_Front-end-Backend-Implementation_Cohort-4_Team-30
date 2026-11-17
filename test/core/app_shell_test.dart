import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/app.dart';
import 'package:team30_app/core/router/app_router.dart';
import 'package:team30_app/core/widgets/feature_placeholder_page.dart';

/// Title of the tab page that is currently on screen.
String visiblePageTitle(WidgetTester tester) => tester
    .widget<FeaturePlaceholderPage>(find.byType(FeaturePlaceholderPage))
    .title;

void main() {
  testWidgets('app opens on the Home tab', (tester) async {
    await tester.pumpWidget(PharmacyApp(router: createAppRouter()));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(visiblePageTitle(tester), 'Dashboard');
  });

  testWidgets('tapping each tab shows its page', (tester) async {
    await tester.pumpWidget(PharmacyApp(router: createAppRouter()));
    await tester.pumpAndSettle();

    const tabs = {
      'Sell': 'Sell',
      'Stock': 'Inventory',
      'Reports': 'Reports',
      'Settings': 'Settings',
      'Home': 'Dashboard',
    };

    for (final MapEntry(key: label, value: title) in tabs.entries) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();

      expect(visiblePageTitle(tester), title, reason: 'after tapping $label');
    }
  });
}
