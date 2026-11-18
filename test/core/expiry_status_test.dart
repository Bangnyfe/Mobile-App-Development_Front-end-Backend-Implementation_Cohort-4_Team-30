import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/core/utils/expiry_status.dart';

void main() {
  final today = DateTime(2026, 11, 18);

  group('daysUntilExpiry', () {
    test('counts whole days ahead', () {
      expect(daysUntilExpiry(DateTime(2026, 12, 7), today: today), 19);
    });

    test('is 0 on the expiry day and negative after it', () {
      expect(daysUntilExpiry(DateTime(2026, 11, 18), today: today), 0);
      expect(daysUntilExpiry(DateTime(2026, 11, 15), today: today), -3);
    });

    test('ignores the time of day', () {
      expect(
        daysUntilExpiry(
          DateTime(2026, 12, 1, 15, 30),
          today: DateTime(2026, 11, 18, 23, 59),
        ),
        13,
      );
    });
  });

  group('expiryStatusFor', () {
    ExpiryStatus status(DateTime expiry) =>
        expiryStatusFor(expiry, today: today, alertDays: 90);

    test('expired once the expiry day has passed', () {
      expect(status(DateTime(2026, 11, 17)), ExpiryStatus.expired);
    });

    test('expiring today is still expiring soon, not expired', () {
      expect(status(DateTime(2026, 11, 18)), ExpiryStatus.expiringSoon);
    });

    test('expiring soon up to and including the alert period', () {
      // DateTime(y, m, d + n) counts calendar days. Adding a Duration would
      // land an hour short across a daylight-saving change.
      expect(status(DateTime(2026, 11, 18 + 90)), ExpiryStatus.expiringSoon);
      expect(status(DateTime(2026, 11, 18 + 91)), ExpiryStatus.inDate);
    });

    test('follows the alert period from Settings', () {
      final expiry = DateTime(2026, 11, 18 + 45);
      expect(
        expiryStatusFor(expiry, today: today, alertDays: 30),
        ExpiryStatus.inDate,
      );
      expect(
        expiryStatusFor(expiry, today: today, alertDays: 90),
        ExpiryStatus.expiringSoon,
      );
    });
  });

  group('expiryLabel', () {
    String label(DateTime expiry) =>
        expiryLabel(expiry, today: today, alertDays: 90);

    test('matches the prototype chips', () {
      expect(label(DateTime(2026, 12, 7)), '19 days');
      expect(label(DateTime(2026, 11, 19)), '1 day');
      expect(label(DateTime(2026, 11, 18)), 'Expires today');
      expect(label(DateTime(2026, 11, 1)), 'Expired');
      expect(label(DateTime(2027, 11, 18)), 'In date');
    });
  });
}
