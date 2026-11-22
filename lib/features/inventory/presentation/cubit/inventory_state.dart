part of 'inventory_cubit.dart';

enum InventoryStatus { loading, loaded, failure }

/// Every product with its batches, plus the chosen filter chip and search.
///
/// Which items show depends on the day and the alert settings too, so the
/// page works them out with `InventoryRules`.
class InventoryState extends Equatable {
  const InventoryState({
    this.status = InventoryStatus.loading,
    this.items = const [],
    this.filter = InventoryFilter.all,
    this.query = '',
    this.errorMessage,
  });

  final InventoryStatus status;
  final List<InventoryItem> items;
  final InventoryFilter filter;
  final String query;
  final String? errorMessage;

  InventoryState copyWith({
    InventoryStatus? status,
    List<InventoryItem>? items,
    InventoryFilter? filter,
    String? query,
    String? errorMessage,
  }) => InventoryState(
    status: status ?? this.status,
    items: items ?? this.items,
    filter: filter ?? this.filter,
    query: query ?? this.query,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [status, items, filter, query, errorMessage];
}
