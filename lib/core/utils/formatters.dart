import 'package:intl/intl.dart';

/// Shared display formatters so money and dates look the same on every
/// screen.
abstract final class Formatters {
  static final _amount = NumberFormat('#,##0', 'en_US');
  static final _dayHeader = DateFormat('EEEE, d MMM', 'en_US');
  static final _time = DateFormat('HH:mm', 'en_US');

  /// 284500 -> "284,500"
  static String amount(num value) => _amount.format(value);

  /// 284500 -> "RWF 284,500"
  static String rwf(num value) => 'RWF ${amount(value)}';

  /// "Friday, 25 Sep"
  static String dayHeader(DateTime date) => _dayHeader.format(date);

  /// "14:32"
  static String time(DateTime date) => _time.format(date);

  /// 12.04 -> "+12%", -3.6 -> "-4%"
  static String percentChange(double percent) {
    final rounded = percent.round();
    return rounded > 0 ? '+$rounded%' : '$rounded%';
  }

  /// 1 -> "1 item", 3 -> "3 items"
  static String itemCount(int count) => count == 1 ? '1 item' : '$count items';
}
