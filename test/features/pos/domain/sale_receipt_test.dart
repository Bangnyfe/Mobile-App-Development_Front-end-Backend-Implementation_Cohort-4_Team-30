import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/pos/domain/entities/batch_allocation.dart';
import 'package:team30_app/features/pos/domain/entities/cart_item.dart';
import 'package:team30_app/features/pos/domain/entities/payment_method.dart';
import 'package:team30_app/features/pos/domain/entities/sale_receipt.dart';
import 'package:team30_app/features/pos/domain/services/sale_ids.dart';

import '../presentation/pos_page_test_helpers.dart';

void main() {
  final at = DateTime(2026, 9, 25, 14, 32, 5);

  /// 2 × Amoxicillin from AX2407, and 3 × Paracetamol split over two
  /// batches: RWF 5,900 from 3 batches.
  final items = [
    CartItem(
      product: amoxicillin,
      batch: amoxBatch,
      quantity: 2,
      allocations: const [
        BatchAllocation(
          batchId: 'b-ax2407',
          batchNumber: 'AX2407',
          quantity: 2,
        ),
      ],
    ),
    CartItem(
      product: paracetamol,
      batch: paraBatch,
      quantity: 3,
      allocations: const [
        BatchAllocation(
          batchId: 'b-pc2506',
          batchNumber: 'PC2506',
          quantity: 1,
        ),
        BatchAllocation(
          batchId: 'b-pc2601',
          batchNumber: 'PC2601',
          quantity: 2,
        ),
      ],
    ),
  ];

  SaleReceipt receipt({
    String method = PaymentMethods.cash,
    int? cash,
    List<CartItem>? lines,
  }) => SaleReceipt.fromCart(
    receiptNo: '260925-143205',
    createdAt: at,
    pharmacyName: 'Amani Pharmacy',
    pharmacyLocation: 'Nyarugenge, Kigali',
    servedBy: 'Aline Uwase',
    paymentMethod: method,
    items: lines ?? items,
    cashReceived: cash,
  );

  group('SaleReceipt.fromCart', () {
    test('copies each line with its quantity, price and batches', () {
      final lines = receipt(cash: 10000).lines;

      expect(lines, hasLength(2));
      expect(lines.first.productName, 'Amoxicillin 500mg');
      expect(lines.first.quantity, 2);
      expect(lines.first.unitPrice, 2500);
      expect(lines.first.lineTotal, 5000);
      expect(lines.first.batchNumbers, ['AX2407']);
      expect(lines.last.batchNumbers, ['PC2506', 'PC2601']);
    });

    test('totals the lines and gives change on a cash sale', () {
      final sale = receipt(cash: 10000);

      expect(sale.isCash, isTrue);
      expect(sale.total, 5900);
      expect(sale.cashReceived, 10000);
      expect(sale.change, 4100);
    });

    test('counts each batch the sale took stock from once', () {
      expect(receipt(cash: 5900).batchesUpdated, 3);
    });

    test('records Mobile Money and Card as paid in full, with no change', () {
      for (final method in [PaymentMethods.mobileMoney, PaymentMethods.card]) {
        final sale = receipt(method: method, cash: 99999);

        expect(sale.isCash, isFalse);
        expect(sale.cashReceived, 5900);
        expect(sale.change, 0);
      }
    });

    test('treats a cash sale with no amount as paid exactly', () {
      final sale = receipt();

      expect(sale.cashReceived, 5900);
      expect(sale.change, 0);
    });

    test("falls back to the line's batch when it has no allocations", () {
      final sale = receipt(
        cash: 900,
        lines: [CartItem(product: paracetamol, batch: paraBatch, quantity: 3)],
      );

      expect(sale.lines.single.batchNumbers, ['PC2506']);
      expect(sale.batchesUpdated, 0);
    });

    test('is equal to another receipt with the same details', () {
      expect(receipt(cash: 10000), receipt(cash: 10000));
      expect(receipt(cash: 10000), isNot(receipt(cash: 20000)));
    });
  });

  group('SaleIds', () {
    test('receipt number is the date and time of the sale', () {
      expect(SaleIds.receiptNo(at), '260925-143205');
    });

    test('sale ID is unique to the microsecond', () {
      expect(SaleIds.saleId(at), 'sale-${at.microsecondsSinceEpoch}');
      expect(
        SaleIds.saleId(at),
        isNot(SaleIds.saleId(at.add(const Duration(microseconds: 1)))),
      );
    });
  });
}
