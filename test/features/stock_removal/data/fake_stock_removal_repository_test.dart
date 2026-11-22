import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/stock_removal/data/fake_stock_removal_repository.dart';
import 'package:team30_app/features/stock_removal/domain/entities/removal_reason.dart';
import 'package:team30_app/features/stock_removal/domain/entities/stock_removal.dart';
import 'package:team30_app/features/stock_removal/domain/repositories/stock_removal_repository.dart';

void main() {
  final now = DateTime(2026, 11, 21, 10, 14);
  late FakeStockRemovalRepository repository;

  setUp(() => repository = FakeStockRemovalRepository(clock: () => now));

  test('removing stock lowers the batch and records the removal', () async {
    final removal = await repository.removeStock(
      const StockRemovalRequest(
        productId: 'p-metronidazole',
        batchId: 'b-mz2308',
        quantity: 14,
        reason: RemovalReason.expired,
      ),
    );

    expect(removal.quantity, 14);
    expect(removal.costValue, 15400);
    expect(removal.batchNumber, 'MZ2308');
    expect(removal.createdAt, now);
    expect(repository.removals, [removal]);

    final products = await repository.loadProducts();
    final metronidazole = products.firstWhere(
      (product) => product.id == 'p-metronidazole',
    );
    expect(metronidazole.batchById('b-mz2308')!.quantity, 0);
    expect(metronidazole.totalUnits, 9);
  });

  test('refuses to remove more than the batch holds', () async {
    await expectLater(
      repository.removeStock(
        const StockRemovalRequest(
          productId: 'p-metronidazole',
          batchId: 'b-mz2308',
          quantity: 15,
          reason: RemovalReason.expired,
        ),
      ),
      throwsA(isA<StockRemovalFailure>()),
    );
    expect(repository.removals, isEmpty);
  });

  test('refuses Other without a note', () async {
    await expectLater(
      repository.removeStock(
        const StockRemovalRequest(
          productId: 'p-paracetamol',
          batchId: 'b-pc2401',
          quantity: 1,
          reason: RemovalReason.other,
        ),
      ),
      throwsA(isA<StockRemovalFailure>()),
    );
  });
}
