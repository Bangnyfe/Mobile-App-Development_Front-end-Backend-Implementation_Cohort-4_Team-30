import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/core/theme/app_theme.dart';
import 'package:team30_app/core/widgets/status_chip.dart';
import 'package:team30_app/features/inventory/presentation/widgets/fefo_batch_indicator.dart';
import 'package:team30_app/features/pos/domain/entities/pos_batch.dart';

void main() {
  final today = DateTime(2026, 11, 19);
  final expired = PosBatch(
    id: 'b0',
    batchNumber: 'B000',
    expiryDate: DateTime(2026, 11, 1),
    quantity: 4,
  );
  final soonest = PosBatch(
    id: 'b1',
    batchNumber: 'B001',
    expiryDate: DateTime(2026, 12, 5),
    quantity: 3,
  );
  final later = PosBatch(
    id: 'b2',
    batchNumber: 'B002',
    expiryDate: DateTime(2027, 3, 1),
    quantity: 6,
  );
  final batches = [later, expired, soonest];

  Future<void> pumpIndicator(WidgetTester tester, PosBatch batch) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: FefoBatchIndicator(
            batch: batch,
            batches: batches,
            today: today,
          ),
        ),
      ),
    );
  }

  StatusChip chip(WidgetTester tester) =>
      tester.widget<StatusChip>(find.byType(StatusChip));

  testWidgets('an expired batch shows a red Expired chip', (tester) async {
    await pumpIndicator(tester, expired);

    expect(chip(tester).label, 'Expired');
    expect(chip(tester).tone, StatusTone.danger);
  });

  testWidgets('the earliest sellable batch shows a green Sell first chip', (
    tester,
  ) async {
    await pumpIndicator(tester, soonest);

    expect(chip(tester).label, 'Sell first');
    expect(chip(tester).tone, StatusTone.success);
  });

  testWidgets('any other batch shows no chip', (tester) async {
    await pumpIndicator(tester, later);

    expect(find.byType(StatusChip), findsNothing);
  });
}
