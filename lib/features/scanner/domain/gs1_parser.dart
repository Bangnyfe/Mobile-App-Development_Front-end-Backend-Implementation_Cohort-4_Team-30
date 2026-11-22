import 'entities/scanned_code.dart';

/// Reads the barcodes found on medicine packs into a [ScannedCode].
///
/// Understands:
/// * plain product barcodes: EAN-13, UPC-A (12 digits), EAN-8 and GTIN-14
/// * GS1 DataMatrix element strings, as the camera returns them, with
///   groups separated by the GS character
/// * the human-readable form printed beside the code, like
///   `(01)06001007012342(17)271231(10)MZ2308`
///
/// Returns null when the text is not a barcode we can use, including a
/// product code whose check digit is wrong (usually a typing mistake).
abstract final class Gs1Parser {
  /// Group separator (FNC1) between variable-length GS1 fields.
  static const _gs = '\u001d';

  /// Symbology prefixes some scanners put in front of the data, e.g. `]d2`
  /// for GS1 DataMatrix.
  static final _symbologyPrefix = RegExp(r'^\][A-Za-z]\d');

  static final _digits = RegExp(r'^\d+$');
  static const _gtinLengths = {8, 12, 13, 14};
  static final _bracketed = RegExp(r'\((\d{2,4})\)([^(]*)');

  /// GS1 application identifiers we read, and their fixed lengths (null
  /// for variable-length fields, which end at GS or the end of the data).
  static const _fields = <String, int?>{
    '01': 14, // GTIN
    '10': null, // batch or lot number
    '11': 6, // production date (read past, not kept)
    '15': 6, // best before date
    '17': 6, // expiry date
    '21': null, // serial number
  };

  static ScannedCode? parse(String raw) {
    final text = raw.trim().replaceFirst(_symbologyPrefix, '');
    if (text.isEmpty) return null;

    if (_digits.hasMatch(text) && _gtinLengths.contains(text.length)) {
      final gtin = _normalizeGtin(text);
      return gtin == null ? null : ScannedCode(gtin: gtin);
    }

    final fields = text.startsWith('(')
        ? _readBracketed(text)
        : _readElementString(text);
    final gtin = _normalizeGtin(fields['01'] ?? '');
    if (gtin == null) return null;
    return ScannedCode(
      gtin: gtin,
      batchNumber: _nonEmpty(fields['10']),
      expiryDate: _date(fields['17'] ?? fields['15']),
      serialNumber: _nonEmpty(fields['21']),
    );
  }

  /// `(01)…(17)…(10)…`: each identifier is in brackets.
  static Map<String, String> _readBracketed(String text) => {
    for (final match in _bracketed.allMatches(text))
      match.group(1)!: match.group(2)!.trim(),
  };

  /// `01…17…10…<GS>21…`: identifiers run together; variable-length fields
  /// end at GS. Stops at an identifier we don't know, keeping what was read.
  static Map<String, String> _readElementString(String text) {
    final fields = <String, String>{};
    var i = 0;
    while (i + 2 <= text.length) {
      if (text[i] == _gs) {
        i++;
        continue;
      }
      final ai = text.substring(i, i + 2);
      if (!_fields.containsKey(ai)) break;
      i += 2;
      final length = _fields[ai];
      final int end;
      if (length != null) {
        end = i + length;
        if (end > text.length) break;
      } else {
        final gs = text.indexOf(_gs, i);
        end = gs == -1 ? text.length : gs;
      }
      fields[ai] = text.substring(i, end);
      i = end;
    }
    return fields;
  }

  /// The barcode as stored on products: GTIN-14s that start with 0 and
  /// UPC-A codes become the 13 digits printed on the box. Null if the check
  /// digit is wrong.
  static String? _normalizeGtin(String code) {
    if (!_digits.hasMatch(code) || !_gtinLengths.contains(code.length)) {
      return null;
    }
    if (!_checkDigitIsValid(code)) return null;
    if (code.length == 14 && code.startsWith('0')) return code.substring(1);
    if (code.length == 12) return '0$code';
    return code;
  }

  /// The GS1 mod-10 check: from the right, digits are weighted 3, 1, 3, …
  static bool _checkDigitIsValid(String code) {
    var sum = 0;
    for (var i = 0; i < code.length - 1; i++) {
      final digit = code.codeUnitAt(code.length - 2 - i) - 48;
      sum += digit * (i.isEven ? 3 : 1);
    }
    final check = (10 - sum % 10) % 10;
    return check == code.codeUnitAt(code.length - 1) - 48;
  }

  /// GS1 dates are YYMMDD; day 00 means the last day of the month.
  static DateTime? _date(String? yymmdd) {
    if (yymmdd == null || !_digits.hasMatch(yymmdd) || yymmdd.length != 6) {
      return null;
    }
    final year = 2000 + int.parse(yymmdd.substring(0, 2));
    final month = int.parse(yymmdd.substring(2, 4));
    final day = int.parse(yymmdd.substring(4, 6));
    if (month < 1 || month > 12) return null;
    // Day 0 of the next month is the last day of this one.
    if (day == 0) return DateTime(year, month + 1, 0);
    final date = DateTime(year, month, day);
    // Rejects days the month doesn't have, which DateTime would roll over.
    return date.month == month && date.day == day ? date : null;
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
