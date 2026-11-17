import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/features/dashboard/domain/greeting.dart';

import '../dashboard_test_data.dart';

void main() {
  group('DashboardSummary.changeVsYesterday', () {
    test('is positive when today is higher', () {
      final summary = buildSummary(
        todaySalesTotal: 112000,
        yesterdaySalesTotal: 100000,
      );
      expect(summary.changeVsYesterday, closeTo(12, 0.001));
    });

    test('is negative when today is lower', () {
      final summary = buildSummary(
        todaySalesTotal: 75000,
        yesterdaySalesTotal: 100000,
      );
      expect(summary.changeVsYesterday, closeTo(-25, 0.001));
    });

    test('is null when there were no sales yesterday', () {
      final summary = buildSummary(yesterdaySalesTotal: 0);
      expect(summary.changeVsYesterday, isNull);
    });
  });

  group('greetingForHour', () {
    test('morning before noon', () {
      expect(greetingForHour(0), 'Good morning');
      expect(greetingForHour(11), 'Good morning');
    });

    test('afternoon from noon until 5 pm', () {
      expect(greetingForHour(12), 'Good afternoon');
      expect(greetingForHour(16), 'Good afternoon');
    });

    test('evening from 5 pm', () {
      expect(greetingForHour(17), 'Good evening');
      expect(greetingForHour(23), 'Good evening');
    });
  });
}
