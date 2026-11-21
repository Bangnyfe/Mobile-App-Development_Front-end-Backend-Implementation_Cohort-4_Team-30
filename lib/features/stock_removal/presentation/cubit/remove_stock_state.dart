part of 'remove_stock_cubit.dart';

enum RemoveStockStatus { loading, ready, loadFailure }

enum SubmitStatus { idle, submitting, success, failure }

class RemoveStockState extends Equatable {
  const RemoveStockState({
    this.status = RemoveStockStatus.loading,
    this.products = const [],
    this.query = '',
    this.productId,
    this.batchId,
    this.quantity = 0,
    this.reason,
    this.suggestedReason,
    this.note = '',
    this.submitStatus = SubmitStatus.idle,
    this.message,
    this.result,
  });

  final RemoveStockStatus status;
  final List<RemovableProduct> products;

  /// What is typed in the search box.
  final String query;
  final String? productId;
  final String? batchId;

  /// Units to remove from the selected batch.
  final int quantity;
  final RemovalReason? reason;

  /// Shown with a "Suggested" tag: Expired for an expired batch or when
  /// opened from an expiry notification.
  final RemovalReason? suggestedReason;
  final String note;
  final SubmitStatus submitStatus;

  /// Error to show (load or submit failure).
  final String? message;

  /// The recorded removal, after a successful submit.
  final StockRemoval? result;

  RemovableProduct? get product {
    for (final product in products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  RemovableBatch? get batch {
    final id = batchId;
    return id == null ? null : product?.batchById(id);
  }

  /// Products matching the search box.
  List<RemovableProduct> get visibleProducts =>
      products.where((product) => product.matches(query)).toList();

  String? get quantityError {
    final selected = batch;
    return selected == null
        ? null
        : RemovalRules.quantity(quantity, available: selected.quantity);
  }

  String? get reasonError => RemovalRules.reason(reason, note);

  /// Step 1 is complete: a batch and a valid quantity.
  bool get canContinue => batch != null && quantityError == null;

  /// Step 2 is complete and nothing is being saved.
  bool get canSubmit =>
      canContinue &&
      reasonError == null &&
      submitStatus != SubmitStatus.submitting;

  /// Value written off for the current selection, in RWF.
  int get costValue => batch?.costOf(quantity) ?? 0;

  /// Nullable fields take a function, so `() => null` can clear them.
  RemoveStockState copyWith({
    RemoveStockStatus? status,
    List<RemovableProduct>? products,
    String? query,
    String? Function()? productId,
    String? Function()? batchId,
    int? quantity,
    RemovalReason? Function()? reason,
    RemovalReason? Function()? suggestedReason,
    String? note,
    SubmitStatus? submitStatus,
    String? Function()? message,
    StockRemoval? Function()? result,
  }) {
    return RemoveStockState(
      status: status ?? this.status,
      products: products ?? this.products,
      query: query ?? this.query,
      productId: productId != null ? productId() : this.productId,
      batchId: batchId != null ? batchId() : this.batchId,
      quantity: quantity ?? this.quantity,
      reason: reason != null ? reason() : this.reason,
      suggestedReason: suggestedReason != null
          ? suggestedReason()
          : this.suggestedReason,
      note: note ?? this.note,
      submitStatus: submitStatus ?? this.submitStatus,
      message: message != null ? message() : this.message,
      result: result != null ? result() : this.result,
    );
  }

  @override
  List<Object?> get props => [
    status,
    products,
    query,
    productId,
    batchId,
    quantity,
    reason,
    suggestedReason,
    note,
    submitStatus,
    message,
    result,
  ];
}
