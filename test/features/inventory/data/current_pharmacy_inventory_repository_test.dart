import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/inventory/data/current_pharmacy_inventory_repository.dart';
import 'package:team30_app/features/inventory/data/fake_inventory_repository.dart';
import 'package:team30_app/features/inventory/domain/inventory_failure.dart';

void main() {
  String? pharmacyId;
  late List<String> created;
  late CurrentPharmacyInventoryRepository repository;

  setUp(() {
    pharmacyId = 'ph1';
    created = [];
    repository = CurrentPharmacyInventoryRepository(
      pharmacyId: () => pharmacyId,
      forPharmacy: (id) {
        created.add(id);
        return FakeInventoryRepository();
      },
    );
  });

  test('uses the signed-in pharmacy, made once', () async {
    await repository.watchInventory().first;
    await repository.findByBarcode('6001007012342');

    expect(created, ['ph1']);
  });

  test('switches when another pharmacy signs in', () async {
    await repository.watchInventory().first;
    pharmacyId = 'ph2';
    await repository.watchInventory().first;

    expect(created, ['ph1', 'ph2']);
  });

  test('without a pharmacy, streams and calls fail with a message', () async {
    pharmacyId = null;

    await expectLater(
      repository.watchInventory(),
      emitsError(
        isA<InventoryFailure>().having(
          (f) => f.message,
          'message',
          CurrentPharmacyInventoryRepository.noPharmacyMessage,
        ),
      ),
    );
    await expectLater(
      repository.findByBarcode('123'),
      throwsA(isA<InventoryFailure>()),
    );
  });
}
