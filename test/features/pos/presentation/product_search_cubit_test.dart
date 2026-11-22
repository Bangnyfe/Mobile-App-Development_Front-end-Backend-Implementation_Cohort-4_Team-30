import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/pos/data/fake_product_catalog.dart';
import 'package:team30_app/features/pos/domain/entities/pos_product.dart';
import 'package:team30_app/features/pos/domain/repositories/product_catalog.dart';
import 'package:team30_app/features/pos/presentation/cubit/product_search_cubit.dart';
import 'package:team30_app/features/scanner/domain/entities/found_product.dart';

import 'pos_page_test_helpers.dart';

/// A catalog whose product list the test controls.
class _LiveCatalog implements ProductCatalog {
  final controller = StreamController<List<CatalogProduct>>.broadcast();
  FoundProduct? Function(String id) load = (_) => null;
  int watches = 0;

  @override
  Stream<List<CatalogProduct>> watchProducts() {
    watches++;
    return controller.stream;
  }

  @override
  Future<FoundProduct?> loadProduct(String productId) async => load(productId);
}

CatalogProduct _item(String id, String name, {String barcode = ''}) =>
    CatalogProduct(
      product: PosProduct(
        id: id,
        barcode: barcode,
        name: name,
        sellingPrice: 100,
      ),
    );

void main() {
  List<String> names(ProductSearchState state) => [
    for (final item in state.results) item.product.name,
  ];

  group('search', () {
    late FakeProductCatalog catalog;

    setUp(() => catalog = FakeProductCatalog(clock: () => today));

    blocTest<ProductSearchCubit, ProductSearchState>(
      'matches any part of the name, in any case',
      build: () => ProductSearchCubit(catalog),
      act: (cubit) => cubit.search('  CETAM '),
      wait: Duration.zero,
      verify: (cubit) {
        expect(cubit.state.query, 'CETAM');
        expect(cubit.state.status, SearchStatus.ready);
        expect(names(cubit.state), ['Paracetamol 500mg']);
      },
    );

    blocTest<ProductSearchCubit, ProductSearchState>(
      'lists names that start with the query first',
      build: () => ProductSearchCubit(
        _StaticCatalog([
          _item('1', 'Vitamin C'),
          _item('2', 'Cough syrup'),
          _item('3', 'Cetirizine'),
        ]),
      ),
      act: (cubit) => cubit.search('c'),
      wait: Duration.zero,
      verify: (cubit) => expect(names(cubit.state), [
        'Cough syrup',
        'Cetirizine',
        'Vitamin C',
      ]),
    );

    blocTest<ProductSearchCubit, ProductSearchState>(
      'also matches the start of a barcode',
      build: () => ProductSearchCubit(catalog),
      act: (cubit) => cubit.search('600100704'),
      wait: Duration.zero,
      verify: (cubit) => expect(names(cubit.state), ['Paracetamol 500mg']),
    );

    blocTest<ProductSearchCubit, ProductSearchState>(
      'shows at most maxResults products',
      build: () => ProductSearchCubit(
        _StaticCatalog([for (var i = 0; i < 30; i++) _item('$i', 'Item $i')]),
      ),
      act: (cubit) => cubit.search('item'),
      wait: Duration.zero,
      verify: (cubit) =>
          expect(cubit.state.results, hasLength(ProductSearchCubit.maxResults)),
    );

    blocTest<ProductSearchCubit, ProductSearchState>(
      'an empty query clears the search',
      build: () => ProductSearchCubit(catalog),
      act: (cubit) async {
        cubit.search('para');
        await Future<void>.delayed(Duration.zero);
        cubit.search('   ');
      },
      verify: (cubit) {
        expect(cubit.state.isSearching, isFalse);
        expect(cubit.state.results, isEmpty);
        expect(cubit.state.status, SearchStatus.ready);
      },
    );

    blocTest<ProductSearchCubit, ProductSearchState>(
      'shows an error when the products cannot load, and retries',
      build: () => ProductSearchCubit(catalog..fail = true),
      act: (cubit) async {
        cubit.search('para');
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.status, SearchStatus.failure);
        expect(cubit.state.message, ProductSearchCubit.loadFailedMessage);

        catalog.fail = false;
        cubit.search('para');
        await Future<void>.delayed(Duration.zero);
      },
      verify: (cubit) {
        expect(cubit.state.status, SearchStatus.ready);
        expect(cubit.state.message, isNull);
        expect(names(cubit.state), ['Paracetamol 500mg']);
      },
    );

    blocTest<ProductSearchCubit, ProductSearchState>(
      'loads again after a failed load is cleared',
      build: () => ProductSearchCubit(catalog..fail = true),
      act: (cubit) async {
        cubit.search('para');
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.status, SearchStatus.failure);

        cubit.clear();
        expect(cubit.state.status, SearchStatus.idle);

        catalog.fail = false;
        cubit.search('para');
        await Future<void>.delayed(Duration.zero);
      },
      verify: (cubit) {
        expect(cubit.state.status, SearchStatus.ready);
        expect(cubit.state.message, isNull);
        expect(names(cubit.state), ['Paracetamol 500mg']);
      },
    );
  });

  group('live products', () {
    test('loads the list once and follows its changes', () async {
      final catalog = _LiveCatalog();
      final cubit = ProductSearchCubit(catalog);
      addTearDown(cubit.close);

      cubit.search('am');
      expect(cubit.state.status, SearchStatus.loading);
      catalog.controller.add([_item('1', 'Amoxicillin')]);
      await Future<void>.delayed(Duration.zero);
      expect(names(cubit.state), ['Amoxicillin']);

      cubit.search('amo');
      catalog.controller.add([
        _item('1', 'Amoxicillin'),
        _item('2', 'Amodiaquine'),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(names(cubit.state), ['Amoxicillin', 'Amodiaquine']);
      expect(catalog.watches, 1);
    });
  });

  group('open', () {
    blocTest<ProductSearchCubit, ProductSearchState>(
      'loads the product with its batches',
      build: () => ProductSearchCubit(FakeProductCatalog(clock: () => today)),
      act: (cubit) => cubit.open('p-paracetamol'),
      verify: (cubit) {
        expect(cubit.state.opening, isFalse);
        expect(cubit.state.opened?.product.name, 'Paracetamol 500mg');
        expect(cubit.state.opened?.batches.single.batchNumber, 'PC2401');
      },
    );

    blocTest<ProductSearchCubit, ProductSearchState>(
      'says when the product no longer exists',
      build: () => ProductSearchCubit(FakeProductCatalog(clock: () => today)),
      act: (cubit) => cubit.open('deleted'),
      verify: (cubit) {
        expect(cubit.state.opened, isNull);
        expect(cubit.state.message, ProductSearchCubit.goneMessage);
      },
    );

    blocTest<ProductSearchCubit, ProductSearchState>(
      'says when the product cannot be loaded',
      build: () => ProductSearchCubit(
        FakeProductCatalog(clock: () => today)..fail = true,
      ),
      act: (cubit) => cubit.open('p-paracetamol'),
      verify: (cubit) {
        expect(cubit.state.opening, isFalse);
        expect(cubit.state.message, ProductSearchCubit.openFailedMessage);
      },
    );

    blocTest<ProductSearchCubit, ProductSearchState>(
      'clear forgets the opened product',
      build: () => ProductSearchCubit(FakeProductCatalog(clock: () => today)),
      act: (cubit) async {
        await cubit.open('p-paracetamol');
        cubit.clear();
      },
      verify: (cubit) => expect(cubit.state.opened, isNull),
    );
  });
}

class _StaticCatalog implements ProductCatalog {
  _StaticCatalog(this.products);

  final List<CatalogProduct> products;

  @override
  Stream<List<CatalogProduct>> watchProducts() => Stream.value(products);

  @override
  Future<FoundProduct?> loadProduct(String productId) async => null;
}
