import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/stock_removal/data/current_pharmacy_stock_removal_repository.dart';
import 'package:team30_app/features/stock_removal/data/fake_stock_removal_repository.dart';
import 'package:team30_app/features/stock_removal/domain/entities/removal_reason.dart';
import 'package:team30_app/features/stock_removal/domain/entities/stock_removal.dart';
import 'package:team30_app/features/stock_removal/domain/repositories/stock_removal_repository.dart';

void main() {
  const request = StockRemovalRequest(
    productId: 'p-metronidazole',
    batchId: 'b-mz2308',
    quantity: 1,
    reason: RemovalReason.damaged,
  );

  test('signed out: no products, and removing is refused', () async {
    final repository = CurrentPharmacyStockRemovalRepository(
      pharmacyId: () => null,
      forPharmacy: (_) => FakeStockRemovalRepository(),
    );

    expect(await repository.loadProducts(), isEmpty);
    await expectLater(
      repository.removeStock(request),
      throwsA(isA<StockRemovalFailure>()),
    );
  });

  test('uses one repository per pharmacy and switches with the user', () async {
    String? pharmacyId = 'pharmacy-a';
    final created = <String>[];
    final repository = CurrentPharmacyStockRemovalRepository(
      pharmacyId: () => pharmacyId,
      forPharmacy: (id) {
        created.add(id);
        return FakeStockRemovalRepository();
      },
    );

    await repository.loadProducts();
    await repository.removeStock(request);
    expect(created, ['pharmacy-a']);

    pharmacyId = 'pharmacy-b';
    await repository.loadProducts();
    expect(created, ['pharmacy-a', 'pharmacy-b']);
  });
}
