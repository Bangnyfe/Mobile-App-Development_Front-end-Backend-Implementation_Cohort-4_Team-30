import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team30_app/features/inventory/domain/entities/batch.dart';
import 'package:team30_app/features/inventory/domain/entities/product.dart';
import 'package:team30_app/features/inventory/domain/repositories/batch_repository.dart';
import 'package:team30_app/features/inventory/domain/repositories/product_repository.dart';
import 'package:team30_app/features/pos/data/current_pharmacy_product_catalog.dart';
import 'package:team30_app/features/pos/data/fake_product_catalog.dart';
import 'package:team30_app/features/pos/data/inventory_product_catalog.dart';
import 'package:team30_app/features/pos/domain/entities/pos_product.dart';
import 'package:team30_app/features/pos/domain/repositories/product_catalog.dart';
import 'package:team30_app/features/scanner/domain/entities/found_product.dart';

class _MockProducts extends Mock implements ProductRepository {}

class _MockBatches extends Mock implements BatchRepository {}

class _MockCatalog extends Mock implements ProductCatalog {}

void main() {
  const amoxicillin = Product(
    id: 'amox',
    barcode: '6001234567895',
    name: 'Amoxicillin 500mg',
    form: 'Capsules',
    packSize: 'box of 21',
    sellingPrice: 2500,
  );
  const noBarcode = Product(
    id: 'ors',
    barcode: '',
    name: 'ORS sachet',
    packSize: '  ',
    sellingPrice: 300,
  );
  final batch = Batch(
    id: 'b1',
    pharmacyId: 'ph1',
    productId: 'amox',
    batchNumber: 'AX2407',
    expiryDate: DateTime(2026, 10, 14),
    quantity: 18,
    costPrice: 1800,
    receivedBy: 'u1',
  );

  group('InventoryProductCatalog', () {
    late _MockProducts products;
    late _MockBatches batches;
    late InventoryProductCatalog catalog;

    setUp(() {
      products = _MockProducts();
      batches = _MockBatches();
      catalog = InventoryProductCatalog(products: products, batches: batches);
    });

    test('lists products with their price and details', () async {
      when(products.watchProducts)
          .thenAnswer((_) => Stream.value([amoxicillin, noBarcode]));

      final listed = await catalog.watchProducts().first;

      expect(listed, [
        const CatalogProduct(
          product: PosProduct(
            id: 'amox',
            barcode: '6001234567895',
            name: 'Amoxicillin 500mg',
            sellingPrice: 2500,
          ),
          details: 'Capsules · box of 21',
        ),
        const CatalogProduct(
          product: PosProduct(
            id: 'ors',
            barcode: '',
            name: 'ORS sachet',
            sellingPrice: 300,
          ),
        ),
      ]);
    });

    test('loads a product with its batches for Product found', () async {
      when(() => products.getProduct('amox'))
          .thenAnswer((_) async => amoxicillin);
      when(() => batches.watchBatches('amox'))
          .thenAnswer((_) => Stream.value([batch]));

      final found = await catalog.loadProduct('amox');

      expect(found?.product.name, 'Amoxicillin 500mg');
      expect(found?.details, 'Capsules · box of 21');
      final sold = found!.batches.single;
      expect(sold.id, 'b1');
      expect(sold.batchNumber, 'AX2407');
      expect(sold.expiryDate, DateTime(2026, 10, 14));
      expect(sold.quantity, 18);
    });

    test(
      'returns null for a deleted product without reading batches',
      () async {
        when(() => products.getProduct('gone')).thenAnswer((_) async => null);

        expect(await catalog.loadProduct('gone'), isNull);
        verifyNever(() => batches.watchBatches(any()));
      },
    );
  });

  group('CurrentPharmacyProductCatalog', () {
    test('has no products without a pharmacy', () async {
      final catalog = CurrentPharmacyProductCatalog(
        pharmacyId: () => null,
        forPharmacy: (_) => fail('no pharmacy, no catalog'),
      );

      expect(await catalog.watchProducts().first, isEmpty);
      expect(await catalog.loadProduct('amox'), isNull);
    });

    test(
      "uses the signed-in user's pharmacy, made once per pharmacy",
      () async {
        String? pharmacy = 'ph1';
        final made = <String>[];
        final inner = _MockCatalog();
        when(inner.watchProducts).thenAnswer((_) => Stream.value(const []));
        when(() => inner.loadProduct(any())).thenAnswer(
          (_) async => FoundProduct(
            product: const PosProduct(
              id: 'amox',
              barcode: '',
              name: 'Amoxicillin',
              sellingPrice: 1,
            ),
          ),
        );
        final catalog = CurrentPharmacyProductCatalog(
          pharmacyId: () => pharmacy,
          forPharmacy: (id) {
            made.add(id);
            return inner;
          },
        );

        await catalog.watchProducts().first;
        await catalog.loadProduct('amox');
        expect(made, ['ph1']);

        pharmacy = 'ph2';
        await catalog.watchProducts().first;
        expect(made, ['ph1', 'ph2']);
      },
    );
  });

  group('FakeProductCatalog', () {
    test('lists the sample products by name', () async {
      final listed = await FakeProductCatalog().watchProducts().first;
      final names = [for (final item in listed) item.product.name];

      expect(names, [...names]..sort());
      expect(names, contains('Paracetamol 500mg'));
    });

    test(
      'finds a sample product by ID, and nothing for an unknown one',
      () async {
        final catalog = FakeProductCatalog();

        expect(
          (await catalog.loadProduct('p-paracetamol'))?.product.name,
          'Paracetamol 500mg',
        );
        expect(await catalog.loadProduct('nope'), isNull);
      },
    );
  });
}
