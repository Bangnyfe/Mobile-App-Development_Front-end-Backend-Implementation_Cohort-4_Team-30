part of 'register_product_cubit.dart';

class RegisterProductState extends Equatable {
  const RegisterProductState({
    this.categories = const [],
    this.saving = false,
    this.errorMessage,
    this.saved,
  });

  final List<ProductCategory> categories;
  final bool saving;

  /// Why the last save failed, e.g. the barcode is already registered.
  final String? errorMessage;

  /// Set once the product is saved, with its new ID.
  final Product? saved;

  RegisterProductState copyWith({
    List<ProductCategory>? categories,
    bool? saving,
    String? errorMessage,
    Product? saved,
  }) => RegisterProductState(
    categories: categories ?? this.categories,
    saving: saving ?? this.saving,
    errorMessage: errorMessage,
    saved: saved ?? this.saved,
  );

  @override
  List<Object?> get props => [categories, saving, errorMessage, saved];
}
