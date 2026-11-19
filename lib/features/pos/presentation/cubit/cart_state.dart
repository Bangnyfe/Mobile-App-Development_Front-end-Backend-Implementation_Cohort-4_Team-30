import 'package:equatable/equatable.dart';

import '../../domain/entities/cart_item.dart';

class CartState extends Equatable {
  const CartState({required this.items, this.error, this.errorCount = 0});

  const CartState.initial() : items = const [], error = null, errorCount = 0;

  final List<CartItem> items;
  final String? error;

  /// Goes up by one on every error. Cubit states that are equal aren't
  /// emitted again, so without this the same message twice in a row (e.g.
  /// adding too many units twice) would only show its SnackBar once.
  final int errorCount;

  int get itemCount =>
      items.fold<int>(0, (count, item) => count + item.quantity);

  int get total => items.fold<int>(0, (sum, item) => sum + item.lineTotal);

  CartState copyWith({List<CartItem>? items, String? error}) => CartState(
    items: items ?? this.items,
    error: error,
    errorCount: errorCount,
  );

  /// Same cart, with [message] as a new error.
  CartState withError(String message) =>
      CartState(items: items, error: message, errorCount: errorCount + 1);

  @override
  List<Object?> get props => [items, error, errorCount];
}
