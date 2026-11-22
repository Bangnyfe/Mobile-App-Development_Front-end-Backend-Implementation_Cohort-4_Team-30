import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/pos/domain/entities/pos_batch.dart';
import 'package:team30_app/features/pos/domain/entities/pos_product.dart';
import 'package:team30_app/features/scanner/data/current_pharmacy_product_lookup_repository.dart';
import 'package:team30_app/features/scanner/data/fake_product_lookup_repository.dart';
import 'package:team30_app/features/scanner/data/product_firestore_mapper.dart';
import 'package:team30_app/features/scanner/domain/entities/found_product.dart';
import 'package:team30_app/features/scanner/domain/gs1_parser.dart';

void main() {
  final now = DateTime(2026, 11, 21, 10);

  group('foundProductFromFirestore', () {
    test('reads the ERD fields, batches earliest expiry first', () {
      final found = foundProductFromFirestore(
        productId: 'p1',
        product: {
          'barcode': '6001007012342',
          'name': 'Metronidazole 400mg',
          'form': 'Tablets',
          'packSize': 'strip of 10',
          'sellingPrice': 1500,
        },
        batches: [
          (
            id: 'b2',
            data: {
              'batchNumber': 'MZ2410',
              'expiryDate': Timestamp.fromDate(DateTime(2028, 4, 1)),
              'quantity': 9,
            },
          ),
          (
            id: 'b1',
            data: {
              'batchNumber': 'MZ2308',
              'expiryDate': Timestamp.fromDate(DateTime(2026, 10, 27)),
              'quantity': 14,
            },
          ),
        ],
      );

      expect(
        found.product,
        const PosProduct(
          id: 'p1',
          barcode: '6001007012342',
          name: 'Metronidazole 400mg',
          sellingPrice: 1500,
        ),
      );
      expect(found.details, 'Tablets · strip of 10');
      expect(found.batches.map((b) => b.id), ['b1', 'b2']);
      expect(found.batches.first.quantity, 14);
    });

    test('leaves out batches without an expiry date or quantity', () {
      final found = foundProductFromFirestore(
        productId: 'p1',
        product: const {'name': 'Something', 'sellingPrice': 100},
        batches: [
          (id: 'no-expiry', data: const {'quantity': 5}),
          (
            id: 'no-quantity',
            data: {'expiryDate': Timestamp.fromDate(DateTime(2027))},
          ),
        ],
      );

      expect(found.batches, isEmpty);
      expect(found.details, '');
    });

    test('copes with missing product fields', () {
      final found = foundProductFromFirestore(
        productId: 'p1',
        product: const {},
        batches: const [],
      );

      expect(found.product.name, 'Unnamed product');
      expect(found.product.sellingPrice, 0);
    });
  });

  group('FoundProduct', () {
    final found = FoundProduct(
      product: const PosProduct(
        id: 'p',
        barcode: '1',
        name: 'P',
        sellingPrice: 10,
      ),
      batches: [
        PosBatch(
          id: 'ok',
          batchNumber: 'OK-1',
          expiryDate: DateTime(2027),
          quantity: 5,
        ),
        PosBatch(
          id: 'old',
          batchNumber: 'OLD-1',
          expiryDate: DateTime(2026, 1, 1),
          quantity: 3,
        ),
      ],
    );

    test('counts all units and the ones that can be sold today', () {
      expect(found.totalUnits, 8);
      expect(found.sellableUnitsOn(now), 5);
    });

    test('finds a batch by its number, ignoring case and spaces', () {
      expect(found.batchNumbered(' ok-1 ')?.id, 'ok');
      expect(found.batchNumbered('missing'), isNull);
    });
  });

  group('FakeProductLookupRepository', () {
    test('every sample barcode can be scanned or typed', () async {
      for (final sample in FakeProductLookupRepository.sampleProducts(now)) {
        final code = Gs1Parser.parse(sample.product.barcode);
        expect(code?.gtin, sample.product.barcode, reason: sample.product.name);
      }
    });

    test('finds a product by barcode, or null', () async {
      final repository = FakeProductLookupRepository(clock: () => now);

      final found = await repository.findByBarcode('6001007012342');

      expect(found?.product.name, 'Metronidazole 400mg');
      expect(await repository.findByBarcode('0000000000000'), isNull);
    });
  });

  group('CurrentPharmacyProductLookupRepository', () {
    test('looks up in the signed-in user’s pharmacy', () async {
      String? pharmacyId = 'p1';
      final created = <String>[];
      final repository = CurrentPharmacyProductLookupRepository(
        pharmacyId: () => pharmacyId,
        forPharmacy: (id) {
          created.add(id);
          return id == 'p1'
              ? FakeProductLookupRepository(clock: () => now)
              : FakeProductLookupRepository(products: const []);
        },
      );

      expect(await repository.findByBarcode('6001007012342'), isNotNull);
      expect(await repository.findByBarcode('6001007045678'), isNotNull);
      expect(created, ['p1']);

      pharmacyId = 'p2';
      expect(await repository.findByBarcode('6001007012342'), isNull);

      pharmacyId = null;
      expect(await repository.findByBarcode('6001007012342'), isNull);
      expect(created, ['p1', 'p2']);
    });
  });
}
