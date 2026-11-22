/// The periods on the Expiry and waste report ("This month",
/// "3 months", "Year"). Each is counted in whole calendar months up to and
/// including the current one.
enum ReportPeriod {
  thisMonth('This month', 1),
  threeMonths('3 months', 3),
  year('Year', 12);

  const ReportPeriod(this.label, this.months);

  final String label;

  /// Calendar months covered, including the current one.
  final int months;

  /// Midnight on the 1st of the period's first month.
  DateTime startOn(DateTime today) =>
      DateTime(today.year, today.month - (months - 1));
}
