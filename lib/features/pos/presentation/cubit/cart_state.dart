import 'package:equatable/equatable.dart';

import '../../domain/entities/cart_item.dart';

class CartState extends Equatable {
  const CartState({required this.items, this.error});

  const CartState.initial() : items = const [], error = null;

  final List<CartItem> items;
  final String? error;

  int get itemCount =>
      items.fold<int>(0, (count, item) => count + item.quantity);

  int get total => items.fold<int>(0, (sum, item) => sum + item.lineTotal);

  CartState copyWith({List<CartItem>? items, String? error}) =>
      CartState(items: items ?? this.items, error: error);

  @override
  List<Object?> get props => [items, error];
}
