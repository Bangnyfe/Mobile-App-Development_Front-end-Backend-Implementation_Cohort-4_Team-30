part of 'batch_pick_cubit.dart';

class BatchPickState extends Equatable {
  const BatchPickState({
    required this.sellable,
    required this.selected,
    required this.quantity,
    this.inCart = const {},
  });

  /// In stock and not expired, earliest expiry first.
  final List<PosBatch> sellable;

  /// Null when nothing can be sold.
  final PosBatch? selected;

  final int quantity;

  /// Units of each batch (by ID) already in the cart.
  final Map<String, int> inCart;

  /// The FEFO batch, shown as "Earliest expiry suggested".
  PosBatch? get suggested => sellable.firstOrNull;

  /// Units of the selected batch already in the cart.
  int get reserved => selected == null ? 0 : inCart[selected!.id] ?? 0;

  /// Most units that can still be added from the selected batch.
  int get max {
    final batch = selected;
    if (batch == null) return 0;
    final left = batch.quantity - reserved;
    return left < 0 ? 0 : left;
  }

  bool get canAdd => selected != null && quantity >= 1 && quantity <= max;

  /// The selected batch's stock once this sale (and what's already in the
  /// cart from it) is confirmed.
  int get stockAfter => (selected?.quantity ?? 0) - reserved - quantity;

  BatchPickState copyWith({PosBatch? selected, int? quantity}) =>
      BatchPickState(
        sellable: sellable,
        selected: selected ?? this.selected,
        quantity: quantity ?? this.quantity,
        inCart: inCart,
      );

  @override
  List<Object?> get props => [sellable, selected, quantity, inCart];
}
