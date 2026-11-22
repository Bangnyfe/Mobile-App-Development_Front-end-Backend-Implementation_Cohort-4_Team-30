import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/stock_removal/data/stock_removal_firestore_mapper.dart';
import 'package:team30_app/features/stock_removal/domain/entities/removable_product.dart';
import 'package:team30_app/features/stock_removal/domain/entities/removal_reason.dart';
import 'package:team30_app/features/stock_removal/domain/entities/stock_removal.dart';

void main() {
  group('batchFromFirestore', () {
    test('reads a complete batch document', () {
      final batch = batchFromFirestore('b1', {
        'batchNumber': 'MZ2308',
        'expiryDate': Timestamp.fromDate(DateTime(2026, 10, 27)),
        'quantity': 14,
        'costPrice': 1100,
      });

      expect(batch!.batchNumber, 'MZ2308');
      expect(batch.expiryDate, DateTime(2026, 10, 27));
      expect(batch.quantity, 14);
      expect(batch.costPrice, 1100);
    });

    test('skips a batch without quantity or expiry date', () {
      expect(batchFromFirestore('b1', {'quantity': 3}), isNull);
      expect(
        batchFromFirestore('b1', {
          'expiryDate': Timestamp.fromDate(DateTime(2027)),
        }),
        isNull,
      );
    });

    test('a missing cost price counts as zero and the id stands in for '
        'a missing batch number', () {
      final batch = batchFromFirestore('b1', {
        'expiryDate': Timestamp.fromDate(DateTime(2027)),
        'quantity': 5,
      });
      expect(batch!.costPrice, 0);
      expect(batch.batchNumber, 'b1');
    });
  });

  test('productFromFirestore builds the details line and sorts batches', () {
    final later = RemovableBatch(
      id: 'b2',
      batchNumber: 'MZ2410',
      expiryDate: DateTime(2028),
      quantity: 9,
      costPrice: 1100,
    );
    final sooner = RemovableBatch(
      id: 'b1',
      batchNumber: 'MZ2308',
      expiryDate: DateTime(2026, 10, 27),
      quantity: 14,
      costPrice: 1100,
    );

    final product = productFromFirestore(
      'p1',
      {
        'name': 'Metronidazole 400mg',
        'barcode': '6001007012345',
        'form': 'Tablets',
        'packSize': 'strip of 10',
      },
      [later, sooner],
    );

    expect(product.name, 'Metronidazole 400mg');
    expect(product.details, 'Tablets · strip of 10');
    expect(product.batches.map((b) => b.batchNumber), ['MZ2308', 'MZ2410']);
  });

  test('removalToFirestore writes every ERD field of STOCK_REMOVALS', () {
    final data = removalToFirestore(
      request: const StockRemovalRequest(
        productId: 'p1',
        batchId: 'b1',
        quantity: 14,
        reason: RemovalReason.returnedToSupplier,
        note: '  Supplier recall  ',
      ),
      productName: 'Metronidazole 400mg',
      batchNumber: 'MZ2308',
      costValue: 15400,
      removedBy: 'uid-1',
      removedByName: 'Aline Uwase',
    );

    expect(data, {
      'productId': 'p1',
      'batchId': 'b1',
      'productName': 'Metronidazole 400mg',
      'batchNumber': 'MZ2308',
      'quantity': 14,
      'reason': 'returnedToSupplier',
      'note': 'Supplier recall',
      'costValue': 15400,
      'removedBy': 'uid-1',
      'removedByName': 'Aline Uwase',
      'createdAt': isA<FieldValue>(),
    });
  });

  test('error codes become specific messages', () {
    expect(
      stockRemovalErrorMessage('permission-denied'),
      contains('permission'),
    );
    expect(stockRemovalErrorMessage('unavailable'), contains('internet'));
    expect(stockRemovalErrorMessage('aborted'), contains('changed'));
    expect(
      stockRemovalErrorMessage('something-new'),
      "Couldn't save the removal. Please try again.",
    );
  });
}
