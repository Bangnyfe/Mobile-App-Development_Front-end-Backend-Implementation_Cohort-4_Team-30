import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/stock_removal/data/fake_stock_removal_repository.dart';
import 'package:team30_app/features/stock_removal/data/stock_removal_firestore_mapper.dart';
import 'package:team30_app/features/stock_removal/domain/entities/removal_reason.dart';
import 'package:team30_app/features/stock_removal/domain/entities/stock_removal.dart';

void main() {
  final now = DateTime(2026, 11, 22, 9, 30);

  test('the fake lists sample and new removals, newest first', () async {
    final repository = FakeStockRemovalRepository(clock: () => now);
    await repository.removeStock(
      const StockRemovalRequest(
        productId: 'p-metronidazole',
        batchId: 'b-mz2308',
        quantity: 14,
        reason: RemovalReason.expired,
      ),
    );

    final all = await repository.loadRemovals(since: DateTime(2025, 12));
    expect(all, hasLength(7));
    expect(all.first.batchNumber, 'MZ2308');

    final thisMonth = await repository.loadRemovals(since: DateTime(2026, 11));
    expect(thisMonth.map((r) => r.batchNumber), [
      'MZ2308',
      'IB2108',
      'AMX-2207',
    ]);
  });

  test('removalFromFirestore reads a stock_removals document', () {
    final removal = removalFromFirestore('r1', {
      'productId': 'p1',
      'batchId': 'b1',
      'productName': 'Metronidazole 400mg',
      'batchNumber': 'MZ2308',
      'quantity': 14,
      'reason': 'expired',
      'note': '',
      'costValue': 15400,
      'removedBy': 'uid-1',
      'removedByName': 'Aline Uwase',
      'createdAt': Timestamp.fromDate(now),
    });

    expect(removal!.reason, RemovalReason.expired);
    expect(removal.costValue, 15400);
    expect(removal.removedByName, 'Aline Uwase');
    expect(removal.createdAt, now);
  });

  test('a removal whose server time is not set yet is skipped', () {
    expect(removalFromFirestore('r1', {'quantity': 1}), isNull);
  });
}
