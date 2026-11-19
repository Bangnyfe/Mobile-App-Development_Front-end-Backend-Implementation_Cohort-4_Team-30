import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/sales/data/sale_firestore_mapper.dart';
import 'package:team30_app/features/sales/domain/entities/sale.dart';

void main() {
  test('reads a sale exactly as checkout saves it', () {
    final sale = saleFromFirestore('s1', {
      'receiptNo': '0142',
      'createdAt': Timestamp.fromDate(DateTime(2026, 11, 19, 14, 32)),
      'soldBy': 'u1',
      'paymentMethod': 'Cash',
      'total': 6900,
      'cashReceived': 10000,
      'change': 3100,
      'items': [
        {
          'productId': 'p1',
          'batchId': 'b1',
          'productName': 'Paracetamol 500mg',
          'quantity': 2,
          'unitPrice': 1200,
        },
        {
          'productId': 'p2',
          'batchId': 'b2',
          'productName': 'Amoxicillin 250mg',
          'quantity': 1,
          'unitPrice': 4500,
        },
      ],
    });

    expect(
      sale,
      Sale(
        id: 's1',
        receiptNo: '0142',
        createdAt: DateTime(2026, 11, 19, 14, 32),
        soldBy: 'u1',
        paymentMethod: 'Cash',
        total: 6900,
        cashReceived: 10000,
        change: 3100,
        lines: const [
          SaleLine(
            productId: 'p1',
            batchId: 'b1',
            productName: 'Paracetamol 500mg',
            quantity: 2,
            unitPrice: 1200,
          ),
          SaleLine(
            productId: 'p2',
            batchId: 'b2',
            productName: 'Amoxicillin 250mg',
            quantity: 1,
            unitPrice: 4500,
          ),
        ],
      ),
    );
  });

  test('reads soldByName when the sale has it', () {
    final sale = saleFromFirestore('s1', {
      'soldBy': 'u2',
      'soldByName': 'Eric Mugisha',
    });

    expect(sale.sellerName, 'Eric Mugisha');
  });

  test('copes with missing fields instead of throwing', () {
    final now = DateTime(2026, 11, 19, 9);
    final sale = saleFromFirestore('s1', {'total': 2500}, now: now);

    expect(sale.receiptNo, '');
    expect(sale.createdAt, now);
    expect(sale.paymentMethod, 'Unknown');
    expect(sale.cashReceived, 2500);
    expect(sale.change, 0);
    expect(sale.lines, isEmpty);
  });

  test('accepts numbers stored as doubles and receipt numbers as ints', () {
    final sale = saleFromFirestore('s1', {
      'receiptNo': 142,
      'total': 2500.0,
      'items': [
        {'productName': 'ORS sachets', 'quantity': 1.0, 'unitPrice': 2500.0},
        'not a line',
      ],
    });

    expect(sale.receiptNo, '142');
    expect(sale.total, 2500);
    expect(sale.lines.single.lineTotal, 2500);
  });
}
