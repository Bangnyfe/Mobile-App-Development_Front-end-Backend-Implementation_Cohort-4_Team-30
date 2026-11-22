import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../scanner/domain/entities/found_product.dart';
import '../../domain/repositories/product_catalog.dart';

part 'product_search_state.dart';

/// Searches the pharmacy's products by name (or part of a barcode) as the
/// user types on Sell, and opens the one they pick.
///
/// Firestore can't search inside text, so the product list is loaded once,
/// kept live, and filtered here. A pharmacy has hundreds of products, not
/// millions, so this stays small.
class ProductSearchCubit extends Cubit<ProductSearchState> {
  ProductSearchCubit(this._catalog) : super(const ProductSearchState());

  final ProductCatalog _catalog;
  StreamSubscription<List<CatalogProduct>>? _subscription;
  List<CatalogProduct> _all = const [];

  /// Most results shown at once; typing more narrows them down.
  static const maxResults = 20;

  static const loadFailedMessage =
      "Couldn't load your products. Check your connection and try again.";
  static const openFailedMessage =
      "Couldn't open this product. Check your connection and try again.";
  static const goneMessage =
      'This product no longer exists. It may have been deleted on another '
      'phone.';

  /// Shows the products matching [query]. Empty clears the search.
  void search(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      clear();
      return;
    }
    _start();
    emit(
      state.copyWith(
        query: trimmed,
        results: _matching(trimmed),
        clearMessage: true,
      ),
    );
  }

  /// Loads [productId] with its batches, for Product found.
  Future<void> open(String productId) async {
    if (state.opening) return;
    emit(state.copyWith(opening: true, clearMessage: true));
    try {
      final found = await _catalog.loadProduct(productId);
      if (isClosed) return;
      emit(
        found == null
            ? state.copyWith(opening: false, message: goneMessage)
            : state.copyWith(opening: false, opened: found),
      );
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(opening: false, message: openFailedMessage));
      }
    }
  }

  /// Back to no search, e.g. once the opened product is on screen. The
  /// product list stays loaded for the next search.
  void clear() => emit(
    ProductSearchState(
      status: state.status == SearchStatus.failure
          ? SearchStatus.idle
          : state.status,
    ),
  );

  void _start() {
    if (_subscription != null && state.status != SearchStatus.failure) return;
    _subscription?.cancel();
    emit(state.copyWith(status: SearchStatus.loading));
    _subscription = _catalog.watchProducts().listen(
      (products) {
        _all = products;
        emit(
          state.copyWith(
            status: SearchStatus.ready,
            results: _matching(state.query),
          ),
        );
      },
      onError: (Object _) {
        // Forget the failed subscription so the next search subscribes
        // again, even after clear() has turned failure back into idle.
        _subscription?.cancel();
        _subscription = null;
        emit(
          state.copyWith(
            status: SearchStatus.failure,
            message: loadFailedMessage,
          ),
        );
      },
    );
  }

  /// Names containing [query] (any case), names starting with it first;
  /// also barcodes starting with it, for a partly typed code.
  List<CatalogProduct> _matching(String query) {
    if (query.isEmpty) return const [];
    final wanted = query.toLowerCase();
    final starts = <CatalogProduct>[];
    final contains = <CatalogProduct>[];
    for (final item in _all) {
      final name = item.product.name.toLowerCase();
      if (name.startsWith(wanted)) {
        starts.add(item);
      } else if (name.contains(wanted) ||
          item.product.barcode.startsWith(query)) {
        contains.add(item);
      }
    }
    return [...starts, ...contains].take(maxResults).toList();
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
