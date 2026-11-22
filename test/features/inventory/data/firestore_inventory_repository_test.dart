import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team30_app/features/inventory/data/combine_latest.dart';
import 'package:team30_app/features/inventory/data/firestore_inventory_repository.dart';
import 'package:team30_app/features/inventory/domain/entities/batch.dart';
import 'package:team30_app/features/inventory/domain/entities/product.dart';
import 'package:team30_app/features/inventory/domain/repositories/batch_repository.dart';
import 'package:team30_app/features/inventory/domain/repositories/category_repository.dart';
import 'package:team30_app/features/inventory/domain/repositories/product_repository.dart';

import '../inventory_test_helpers.dart';

class _MockProducts extends Mock implements ProductRepository {}

class _MockBatches extends Mock implements BatchRepository {}

class _MockCategories extends Mock implements CategoryRepository {}

void main() {
  group('inventoryItemsFrom', () {
    test('gives each product its own batches, in order', () {
      final a = testProduct(id: 'a', name: 'A');
      final b = testProduct(id: 'b', name: 'B');
      final batches = [
        testBatch(id: 'b1', productId: 'b', expiresInDays: 10),
        testBatch(id: 'a1', productId: 'a', expiresInDays: 20),
        testBatch(id: 'b2', productId: 'b', expiresInDays: 30),
        testBatch(id: 'gone', productId: 'deleted', expiresInDays: 40),
      ];

      final items = inventoryItemsFrom([a, b], batches);

      expect(items.map((item) => item.product.id), ['a', 'b']);
      expect(items[0].batches.map((batch) => batch.id), ['a1']);
      expect(items[1].batches.map((batch) => batch.id), ['b1', 'b2']);
    });

    test('a product without batches has none', () {
      final items = inventoryItemsFrom([testProduct()], const []);
      expect(items.single.batches, isEmpty);
    });
  });

  group('combineLatest2', () {
    test('emits once both have emitted, then on every change', () async {
      final first = StreamController<int>();
      final second = StreamController<String>();
      final values = <String>[];
      final subscription = combineLatest2(
        first.stream,
        second.stream,
        (int a, String b) => '$a$b',
      ).listen(values.add);

      first.add(1);
      await pumpEventQueue();
      expect(values, isEmpty);

      second.add('x');
      first.add(2);
      second.add('y');
      await pumpEventQueue();
      expect(values, ['1x', '2x', '2y']);

      await subscription.cancel();
      expect(first.hasListener, isFalse);
      expect(second.hasListener, isFalse);
    });

    test('passes errors on', () async {
      final first = StreamController<int>();
      final combined = combineLatest2(
        first.stream,
        const Stream<int>.empty(),
        (int a, int b) => a + b,
      );
      final error = expectLater(combined, emitsError(isA<StateError>()));
      first.addError(StateError('offline'));
      await error;
      await first.close();
    });
  });

  group('FirestoreInventoryRepository', () {
    late _MockProducts products;
    late _MockBatches batches;
    late FirestoreInventoryRepository repository;

    setUp(() {
      products = _MockProducts();
      batches = _MockBatches();
      repository = FirestoreInventoryRepository(
        products: products,
        batches: batches,
        categories: _MockCategories(),
      );
    });

    test('watchInventory combines products with every batch', () async {
      when(() => products.watchProducts())
          .thenAnswer((_) => Stream.value([testProduct()]));
      when(() => batches.watchAllBatches())
          .thenAnswer((_) => Stream.value([testBatch(quantity: 7)]));

      final items = await repository.watchInventory().first;

      expect(items.single.product.id, 'p1');
      expect(items.single.totalUnits, 7);
    });

    test('watchItem emits null once the product is deleted', () async {
      when(
        () => products.watchProduct('p1'),
      ).thenAnswer((_) => Stream<Product?>.fromIterable([testProduct(), null]));
      when(() => batches.watchBatches('p1'))
          .thenAnswer((_) => Stream<List<Batch>>.value([testBatch()]));

      final items = await repository.watchItem('p1').toList();

      expect(items.first?.product.id, 'p1');
      expect(items.last, isNull);
    });

    test(
      'updatePricing with no reorder level goes back to the default',
      () async {
        when(
          () => products.updatePricing(
            any(),
            sellingPrice: any(named: 'sellingPrice'),
            reorderLevel: any(named: 'reorderLevel'),
            clearReorderLevel: any(named: 'clearReorderLevel'),
          ),
        ).thenAnswer((_) async {});

        await repository.updatePricing('p1', sellingPrice: 5000);
        await repository.updatePricing(
          'p1',
          sellingPrice: 5000,
          reorderLevel: 40,
        );

        verify(
          () => products.updatePricing(
            'p1',
            sellingPrice: 5000,
            reorderLevel: null,
            clearReorderLevel: true,
          ),
        ).called(1);
        verify(
          () => products.updatePricing(
            'p1',
            sellingPrice: 5000,
            reorderLevel: 40,
            clearReorderLevel: false,
          ),
        ).called(1);
      },
    );
  });
}
