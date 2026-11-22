import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/sales/data/current_pharmacy_sales_repository.dart';
import 'package:team30_app/features/sales/domain/repositories/sales_repository.dart';

import '../sales_test_helpers.dart';

void main() {
  final day = DateTime(2026, 11, 21, 10);
  final pharmacySales = {
    'p1': StubSalesRepository(
      sales: [buildSale(id: 'a', createdAt: day)],
    ),
    'p2': StubSalesRepository(
      sales: [buildSale(id: 'b', createdAt: day)],
    ),
  };

  late String? pharmacyId;
  late List<String> created;
  late CurrentPharmacySalesRepository repository;

  setUp(() {
    pharmacyId = 'p1';
    created = [];
    repository = CurrentPharmacySalesRepository(
      pharmacyId: () => pharmacyId,
      forPharmacy: (id) {
        created.add(id);
        return pharmacySales[id]!;
      },
    );
  });

  Future<List<String>> saleIds() async => [
    for (final sale in await repository.watchSales().first) sale.id,
  ];

  test('reads the signed-in user’s pharmacy', () async {
    expect(await saleIds(), ['a']);
    expect((await repository.getSale('a'))?.id, 'a');
    expect(await repository.getSale('b'), isNull);
  });

  test('switches pharmacy when another user signs in', () async {
    expect(await saleIds(), ['a']);

    pharmacyId = 'p2';

    expect(await saleIds(), ['b']);
    expect(await repository.getSale('a'), isNull);
  });

  test('without a pharmacy there are no sales', () async {
    pharmacyId = null;

    expect(await repository.watchSales().first, isEmpty);
    expect(await repository.getSale('a'), isNull);
    expect(created, isEmpty);
  });

  test('reuses the repository while the pharmacy stays the same', () async {
    await saleIds();
    await repository.getSale('a');
    await repository.watchSales(limit: SalesRepository.defaultLimit).first;

    expect(created, ['p1']);
  });
}
