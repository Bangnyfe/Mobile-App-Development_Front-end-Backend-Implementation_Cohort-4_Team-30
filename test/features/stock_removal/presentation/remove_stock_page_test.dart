import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team30_app/features/settings/data/shared_prefs_settings_repository.dart';
import 'package:team30_app/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:team30_app/features/stock_removal/data/fake_stock_removal_repository.dart';
import 'package:team30_app/features/stock_removal/domain/entities/removal_reason.dart';
import 'package:team30_app/features/stock_removal/presentation/cubit/remove_stock_cubit.dart';
import 'package:team30_app/features/stock_removal/presentation/pages/remove_stock_page.dart';

void main() {
  final now = DateTime(2026, 11, 22, 9, 30);

  Future<void> pumpRemoveStock(
    WidgetTester tester, {
    String? productId,
    String? batchId,
    RemovalReason? reason,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) =>
                  SettingsCubit(SharedPrefsSettingsRepository(prefs))..load(),
            ),
            BlocProvider(
              create: (_) =>
                  RemoveStockCubit(
                    FakeStockRemovalRepository(clock: () => now),
                    clock: () => now,
                  )..start(
                    productId: productId,
                    batchId: batchId,
                    suggestedReason: reason,
                  ),
            ),
          ],
          child: RemoveStockPage(clock: () => now),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    final target = find.text(text);
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  FilledButton filledButton(WidgetTester tester, String label) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, label));

  testWidgets('choosing a product offers its expired batch with all units', (
    tester,
  ) async {
    await pumpRemoveStock(tester);
    expect(find.text('Step 1 of 2 · Choose batch'), findsOneWidget);

    await tap(tester, 'Metronidazole 400mg');

    expect(find.text('MZ2308'), findsOneWidget);
    expect(find.text('MZ2410'), findsOneWidget);
    final quantity = tester.widget<Text>(
      find.byKey(const ValueKey('removal-quantity')),
    );
    expect(quantity.data, '14');
  });

  testWidgets('Remove stays disabled until a reason is chosen', (tester) async {
    await pumpRemoveStock(tester);
    await tap(tester, 'Metronidazole 400mg');
    await tap(tester, 'Continue');

    expect(find.text('Step 2 of 2 · Reason'), findsOneWidget);
    expect(
      filledButton(tester, 'Choose a reason to continue').onPressed,
      isNull,
    );

    await tap(tester, 'Damaged');

    expect(filledButton(tester, 'Remove 14 units').onPressed, isNotNull);
  });

  testWidgets('removing shows the confirmation and the value written off', (
    tester,
  ) async {
    await pumpRemoveStock(tester);
    await tap(tester, 'Metronidazole 400mg');
    await tap(tester, 'Continue');
    await tap(tester, 'Expired');
    await tap(tester, 'Remove 14 units');

    expect(find.text('14 units removed'), findsOneWidget);
    expect(find.text('RWF 15,400'), findsOneWidget);
    expect(find.text('23 → 9'), findsOneWidget);
  });

  testWidgets('from a notification it opens on Reason with Expired chosen', (
    tester,
  ) async {
    await pumpRemoveStock(
      tester,
      productId: 'amoxicillin-500',
      batchId: 'b-amx-2309',
      reason: RemovalReason.expired,
    );

    expect(find.textContaining('From notification'), findsOneWidget);
    expect(find.text('Suggested'), findsOneWidget);
    expect(filledButton(tester, 'Remove 40 units').onPressed, isNotNull);
  });
}
