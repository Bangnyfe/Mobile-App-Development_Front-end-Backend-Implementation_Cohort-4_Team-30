import 'entities/inventory_item.dart';

/// The filter chips on the Inventory screen.
enum InventoryFilter {
  all('All'),
  lowStock('Low stock'),
  expiringSoon('Expiring soon'),
  expired('Expired');

  const InventoryFilter(this.label);

  final String label;

  /// The filter named in a link such as `/stock?filter=lowStock`, or [all].
  static InventoryFilter fromName(String? name) =>
      values.firstWhere((filter) => filter.name == name, orElse: () => all);
}

/// What decides which items each filter shows: the day, and the alert
/// settings (Settings › Alerts).
class InventoryRules {
  const InventoryRules({
    required this.today,
    required this.alertDays,
    required this.defaultReorderLevel,
  });

  final DateTime today;

  /// Batches expiring within this many days are "expiring soon".
  final int alertDays;

  /// The reorder level for products that don't have their own.
  final int defaultReorderLevel;

  bool matches(InventoryItem item, InventoryFilter filter) => switch (filter) {
    InventoryFilter.all => true,
    InventoryFilter.lowStock => item.isLowStockOn(
      today,
      defaultReorderLevel: defaultReorderLevel,
    ),
    InventoryFilter.expiringSoon => item.isExpiringSoonOn(
      today,
      alertDays: alertDays,
    ),
    InventoryFilter.expired => item.hasExpiredStockOn(today),
  };

  /// The items [filter] shows whose name or barcode contains [query]
  /// (ignoring case), in the order given.
  List<InventoryItem> apply(
    List<InventoryItem> items, {
    InventoryFilter filter = InventoryFilter.all,
    String query = '',
  }) {
    final search = query.trim().toLowerCase();
    return [
      for (final item in items)
        if (matches(item, filter) && _matchesSearch(item, search)) item,
    ];
  }

  /// How many of [items] each filter shows, for the chip labels.
  Map<InventoryFilter, int> counts(List<InventoryItem> items) => {
    for (final filter in InventoryFilter.values)
      filter: items.where((item) => matches(item, filter)).length,
  };

  static bool _matchesSearch(InventoryItem item, String search) =>
      search.isEmpty ||
      item.product.name.toLowerCase().contains(search) ||
      item.product.barcode.contains(search);
}
