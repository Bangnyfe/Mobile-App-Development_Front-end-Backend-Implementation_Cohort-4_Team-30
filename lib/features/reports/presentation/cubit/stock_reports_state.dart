part of 'stock_reports_cubit.dart';

enum StockReportsStatus { loading, ready, failure }

/// Everything both stock reports show. The totals are worked out by the
/// pure functions in `stock_report.dart`, from the loaded stock and
/// removals, as of [today].
class StockReportsState extends Equatable {
  StockReportsState({
    this.status = StockReportsStatus.loading,
    this.products = const [],
    this.removals = const [],
    this.period = ReportPeriod.thisMonth,
    DateTime? today,
    this.message,
  }) : today = today ?? DateTime(2000);

  final StockReportsStatus status;
  final List<RemovableProduct> products;

  /// The last 12 months of removals, newest first.
  final List<StockRemoval> removals;

  /// Selected on the Expiry and waste report.
  final ReportPeriod period;
  final DateTime today;
  final String? message;

  // Inventory report.
  int get stockValue => stockValueAtCost(products);
  int get productCount => products.length;
  RemovalTotals get thisMonthTotals =>
      totalsOf(removalsSince(removals, ReportPeriod.thisMonth.startOn(today)));

  // Expiry and waste report.
  List<StockRemoval> get expiredRemovedInPeriod => removalsSince(
    removals,
    period.startOn(today),
  ).where((removal) => removal.reason == RemovalReason.expired).toList();
  RemovalTotals get expiredRemovedTotals => totalsOf(expiredRemovedInPeriod);
  List<ExpiredBatchLine> get expiredStillOnShelf =>
      expiredOnShelf(products, today);
  int get expiredOnShelfValue =>
      expiredStillOnShelf.fold(0, (total, line) => total + line.value);
  List<MonthTotal> get expiredByMonth =>
      expiredValueByMonth(removals, today: today, months: period.months);

  StockReportsState copyWith({
    StockReportsStatus? status,
    List<RemovableProduct>? products,
    List<StockRemoval>? removals,
    ReportPeriod? period,
    DateTime? today,
    String? Function()? message,
  }) => StockReportsState(
    status: status ?? this.status,
    products: products ?? this.products,
    removals: removals ?? this.removals,
    period: period ?? this.period,
    today: today ?? this.today,
    message: message != null ? message() : this.message,
  );

  @override
  List<Object?> get props => [
    status,
    products,
    removals,
    period,
    today,
    message,
  ];
}
