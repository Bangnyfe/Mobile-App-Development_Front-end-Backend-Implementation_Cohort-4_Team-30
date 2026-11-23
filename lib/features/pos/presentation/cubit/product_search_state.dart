part of 'product_search_cubit.dart';

/// Whether the product list has loaded.
enum SearchStatus { idle, loading, ready, failure }

class ProductSearchState extends Equatable {
  const ProductSearchState({
    this.status = SearchStatus.idle,
    this.query = '',
    this.results = const [],
    this.opening = false,
    this.opened,
    this.message,
  });

  final SearchStatus status;

  /// What was typed, trimmed. Empty when not searching.
  final String query;

  final List<CatalogProduct> results;

  /// Loading a picked product's batches.
  final bool opening;

  /// The picked product, ready for Product found.
  final FoundProduct? opened;

  /// An error to show, if any.
  final String? message;

  bool get isSearching => query.isNotEmpty;

  ProductSearchState copyWith({
    SearchStatus? status,
    String? query,
    List<CatalogProduct>? results,
    bool? opening,
    FoundProduct? opened,
    String? message,
    bool clearMessage = false,
  }) => ProductSearchState(
    status: status ?? this.status,
    query: query ?? this.query,
    results: results ?? this.results,
    opening: opening ?? this.opening,
    opened: opened ?? this.opened,
    message: clearMessage ? null : message ?? this.message,
  );

  @override
  List<Object?> get props => [status, query, results, opening, opened, message];
}
