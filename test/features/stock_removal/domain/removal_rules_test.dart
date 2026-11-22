import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/stock_removal/domain/entities/removal_reason.dart';
import 'package:team30_app/features/stock_removal/domain/removal_rules.dart';

void main() {
  group('RemovalRules.quantity', () {
    test('accepts 1 up to the units in the batch', () {
      expect(RemovalRules.quantity(1, available: 14), isNull);
      expect(RemovalRules.quantity(14, available: 14), isNull);
    });

    test('rejects zero and more than the batch holds', () {
      expect(
        RemovalRules.quantity(0, available: 14),
        'Remove at least 1 unit.',
      );
      expect(
        RemovalRules.quantity(15, available: 14),
        'Only 14 units are left in this batch.',
      );
      expect(
        RemovalRules.quantity(2, available: 1),
        'Only 1 unit is left in this batch.',
      );
    });

    test('rejects an empty batch', () {
      expect(
        RemovalRules.quantity(1, available: 0),
        'This batch has no units left to remove.',
      );
    });
  });

  group('RemovalRules.reason', () {
    test('a reason is required', () {
      expect(RemovalRules.reason(null, ''), 'Choose a reason to continue.');
      expect(RemovalRules.reason(RemovalReason.damaged, ''), isNull);
    });

    test('Other needs a note', () {
      expect(
        RemovalRules.reason(RemovalReason.other, '  '),
        'Add a note to explain the reason.',
      );
      expect(
        RemovalRules.reason(RemovalReason.other, 'Sample for clinic'),
        isNull,
      );
    });
  });

  test('RemovalReason.fromName reads stored names and falls back to Other', () {
    expect(
      RemovalReason.fromName('returnedToSupplier'),
      RemovalReason.returnedToSupplier,
    );
    expect(RemovalReason.fromName('unknown'), RemovalReason.other);
    expect(RemovalReason.fromName(null), RemovalReason.other);
  });
}
