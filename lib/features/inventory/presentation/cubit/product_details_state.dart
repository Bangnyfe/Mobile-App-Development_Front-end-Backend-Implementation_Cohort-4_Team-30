part of 'product_details_cubit.dart';

enum ProductDetailsStatus { loading, loaded, notFound, failure }

class ProductDetailsState extends Equatable {
  const ProductDetailsState({
    this.status = ProductDetailsStatus.loading,
    this.item,
    this.errorMessage,
    this.saving = false,
  });

  final ProductDetailsStatus status;

  /// Set once loaded.
  final InventoryItem? item;

  /// Why the product couldn't be loaded.
  final String? errorMessage;

  /// True while an edit or delete is being saved, so buttons are disabled.
  final bool saving;

  ProductDetailsState copyWith({
    ProductDetailsStatus? status,
    InventoryItem? item,
    String? errorMessage,
    bool? saving,
  }) => ProductDetailsState(
    status: status ?? this.status,
    item: item ?? this.item,
    errorMessage: errorMessage,
    saving: saving ?? this.saving,
  );

  @override
  List<Object?> get props => [status, item, errorMessage, saving];
}
