import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/inventory/data/fake_inventory_repository.dart';
import 'package:team30_app/features/inventory/domain/inventory_failure.dart';
import 'package:team30_app/features/inventory/domain/inventory_filter.dart';
import 'package:team30_app/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:team30_app/features/inventory/presentation/cubit/product_details_cubit.dart';

import '../inventory_test_helpers.dart';

void main() {
  late FakeInventoryRepository repository;

  setUp(() {
    repository = FakeInventoryRepository(clock: () => inventoryToday);
  });

  group('InventoryCubit', () {
    blocTest<InventoryCubit, InventoryState>(
      'loads every product, sorted by name',
      build: () => InventoryCubit(repository),
      act: (cubit) => cubit.start(),
      wait: Duration.zero,
      verify: (cubit) {
        expect(cubit.state.status, InventoryStatus.loaded);
        expect(cubit.state.items.first.product.name, 'Amoxicillin 500mg');
        expect(cubit.state.items, hasLength(6));
      },
    );

    test('updates live when stock changes', () async {
      final cubit = InventoryCubit(repository);
      addTearDown(cubit.close);
      await cubit.start();
      await pumpEventQueue();

      await repository.deleteProduct('p-paracetamol');
      await pumpEventQueue();

      expect(cubit.state.items, hasLength(5));
    });

    blocTest<InventoryCubit, InventoryState>(
      'shows the failure message',
      build: () => InventoryCubit(repository..fail = true),
      act: (cubit) => cubit.start(),
      wait: Duration.zero,
      verify: (cubit) {
        expect(cubit.state.status, InventoryStatus.failure);
        expect(cubit.state.errorMessage, InventoryFailure.generic);
      },
    );

    blocTest<InventoryCubit, InventoryState>(
      'remembers the filter and search',
      build: () => InventoryCubit(repository),
      act: (cubit) => cubit
        ..selectFilter(InventoryFilter.expired)
        ..search('metro'),
      verify: (cubit) {
        expect(cubit.state.filter, InventoryFilter.expired);
        expect(cubit.state.query, 'metro');
      },
    );

    test('can open on a filter', () {
      final cubit = InventoryCubit(
        repository,
        initialFilter: InventoryFilter.lowStock,
      );
      addTearDown(cubit.close);
      expect(cubit.state.filter, InventoryFilter.lowStock);
    });
  });

  group('ProductDetailsCubit', () {
    Future<ProductDetailsCubit> started(String productId) async {
      final cubit = ProductDetailsCubit(repository, productId);
      addTearDown(cubit.close);
      await cubit.start();
      await pumpEventQueue();
      return cubit;
    }

    test('loads the product with its batches', () async {
      final cubit = await started('amoxicillin-500');

      expect(cubit.state.status, ProductDetailsStatus.loaded);
      expect(cubit.state.item?.batches.map((b) => b.batchNumber), [
        'AMX-2309',
        'AMX-2411',
      ]);
    });

    test('an unknown product is not found', () async {
      final cubit = await started('nope');
      expect(cubit.state.status, ProductDetailsStatus.notFound);
    });

    test('updatePricing saves and shows the new price', () async {
      final cubit = await started('amoxicillin-500');

      final error = await cubit.updatePricing(sellingPrice: 5000);
      await pumpEventQueue();

      expect(error, isNull);
      expect(cubit.state.item?.product.sellingPrice, 5000);
      expect(cubit.state.item?.product.reorderLevel, isNull);
      expect(cubit.state.saving, isFalse);
    });

    test('a pharmacist gets the owner-only message', () async {
      final cubit = await started('amoxicillin-500');
      repository.ownerOnly = true;

      final error = await cubit.updatePricing(sellingPrice: 5000);

      expect(error, InventoryFailure.ownerOnly);
      expect(cubit.state.saving, isFalse);
    });

    test('deleteBatch removes one batch', () async {
      final cubit = await started('amoxicillin-500');

      expect(await cubit.deleteBatch('b-amx-2309'), isNull);
      await pumpEventQueue();

      expect(cubit.state.item?.batches.map((b) => b.id), ['b-amx-2411']);
    });

    test('deleteProduct removes the product and its batches', () async {
      final cubit = await started('amoxicillin-500');

      expect(await cubit.deleteProduct(), isNull);

      expect(
        repository.batches.where((b) => b.productId == 'amoxicillin-500'),
        isEmpty,
      );
      expect(
        repository.products.map((p) => p.id),
        isNot(contains('amoxicillin-500')),
      );
    });
  });
}
