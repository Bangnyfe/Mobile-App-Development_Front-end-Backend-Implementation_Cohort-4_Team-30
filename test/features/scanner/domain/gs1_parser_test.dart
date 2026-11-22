import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/scanner/domain/entities/scanned_code.dart';
import 'package:team30_app/features/scanner/domain/gs1_parser.dart';

/// A valid EAN-13, as printed on a box.
const _ean = '6001007012342';
const _gs = '\u001d';

void main() {
  group('plain product barcodes', () {
    test('reads an EAN-13 as it is', () {
      expect(Gs1Parser.parse(_ean), const ScannedCode(gtin: _ean));
    });

    test('ignores spaces around the code', () {
      expect(Gs1Parser.parse('  $_ean \n')?.gtin, _ean);
    });

    test('a GTIN-14 starting with 0 becomes the 13 printed digits', () {
      expect(Gs1Parser.parse('0$_ean')?.gtin, _ean);
    });

    test('a GTIN-14 for a case of packs keeps all 14 digits', () {
      expect(Gs1Parser.parse('16001007012349')?.gtin, '16001007012349');
    });

    test('a UPC-A gets the leading 0 of its EAN-13 form', () {
      expect(Gs1Parser.parse('036000291452')?.gtin, '0036000291452');
    });

    test('reads an EAN-8', () {
      expect(Gs1Parser.parse('96385074')?.gtin, '96385074');
    });

    test('rejects a wrong check digit, usually a typing mistake', () {
      expect(Gs1Parser.parse('6001007012345'), isNull);
    });

    test('rejects text that is not a barcode', () {
      expect(Gs1Parser.parse(''), isNull);
      expect(Gs1Parser.parse('   '), isNull);
      expect(Gs1Parser.parse('hello'), isNull);
      expect(Gs1Parser.parse('12345'), isNull);
      expect(Gs1Parser.parse('https://example.com'), isNull);
    });
  });

  group('GS1 DataMatrix from the camera', () {
    test('reads product, expiry, batch and serial', () {
      final code = Gs1Parser.parse(
        '010$_ean'
        '17271231'
        '10MZ2308$_gs'
        '21SN123456',
      );

      expect(
        code,
        ScannedCode(
          gtin: _ean,
          expiryDate: DateTime(2027, 12, 31),
          batchNumber: 'MZ2308',
          serialNumber: 'SN123456',
        ),
      );
    });

    test('works in any order, with the symbology prefix', () {
      final code = Gs1Parser.parse(
        ']d2'
        '21SN1$_gs'
        '10AB-12$_gs'
        '010$_ean'
        '17280600',
      );

      expect(code?.gtin, _ean);
      expect(code?.serialNumber, 'SN1');
      expect(code?.batchNumber, 'AB-12');
      // Day 00 means the last day of the month.
      expect(code?.expiryDate, DateTime(2028, 6, 30));
    });

    test('a batch at the very end needs no separator', () {
      final code = Gs1Parser.parse(
        '010${_ean}17271231'
        '10LOT9',
      );

      expect(code?.batchNumber, 'LOT9');
    });

    test('uses the best before date when there is no expiry', () {
      expect(
        Gs1Parser.parse('010${_ean}15270115')?.expiryDate,
        DateTime(2027, 1, 15),
      );
    });

    test('reads past a production date', () {
      final code = Gs1Parser.parse(
        '010${_ean}11250101'
        '17270101',
      );

      expect(code?.expiryDate, DateTime(2027, 1, 1));
    });

    test('keeps what it read before a field it does not know', () {
      final code = Gs1Parser.parse(
        '010${_ean}17271231'
        '99SOMETHING',
      );

      expect(code?.gtin, _ean);
      expect(code?.expiryDate, DateTime(2027, 12, 31));
    });

    test('ignores an impossible expiry date', () {
      expect(Gs1Parser.parse('010${_ean}17270231')?.expiryDate, isNull);
      expect(Gs1Parser.parse('010${_ean}17271301')?.expiryDate, isNull);
    });

    test('rejects a code without a valid product number', () {
      expect(
        Gs1Parser.parse(
          '17271231'
          '10MZ2308',
        ),
        isNull,
      );
      expect(
        Gs1Parser.parse(
          '0106001007012345'
          '17271231',
        ),
        isNull,
      );
      expect(Gs1Parser.parse('01060010070'), isNull);
    });
  });

  group('the human-readable form printed beside the code', () {
    test('reads the bracketed fields', () {
      final code = Gs1Parser.parse('(01)0$_ean(17)271231(10)MZ2308(21)SN9');

      expect(
        code,
        ScannedCode(
          gtin: _ean,
          expiryDate: DateTime(2027, 12, 31),
          batchNumber: 'MZ2308',
          serialNumber: 'SN9',
        ),
      );
    });

    test('allows spaces between the fields', () {
      final code = Gs1Parser.parse('(01) 0$_ean (10) MZ2308');

      expect(code?.gtin, _ean);
      expect(code?.batchNumber, 'MZ2308');
    });
  });
}
