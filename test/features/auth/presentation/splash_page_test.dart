import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/auth/presentation/pages/splash_page.dart';

void main() {
  testWidgets('shows the tagline and a loading indicator', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashPage()));
    await tester.pump(const Duration(milliseconds: 700));

    expect(
      find.text('Stock, sales and expiry, tracked in one scan.'),
      findsOneWidget,
    );
    expect(find.text('Loading your pharmacy'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
