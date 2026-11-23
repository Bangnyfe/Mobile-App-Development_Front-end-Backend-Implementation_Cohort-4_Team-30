import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_quantity_stepper.dart';
import '../../../../core/widgets/pinned_bottom_bar.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/services/fefo_picker.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';

/// The cart: change quantities, remove lines, scan more, then check out.
class CartPage extends StatelessWidget {
  const CartPage({super.key, this.clock = DateTime.now});

  /// For tests; the app uses the real time.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return BlocConsumer<CartCubit, CartState>(
      listenWhen: (previous, current) =>
          current.errorCount != previous.errorCount && current.error != null,
      listener: (context, cart) => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(cart.error!))),
      builder: (context, cart) {
        final today = clock();
        return Scaffold(
          appBar: AppBar(
            title: Text('Cart · ${Formatters.itemCount(cart.items.length)}'),
          ),
          body: Column(
            children: [
              Expanded(
                child: cart.items.isEmpty
                    ? const _EmptyCart()
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            children: [
                              for (final item in cart.items) ...[
                                _CartLine(
                                  key: ValueKey('cart-line-${item.product.id}'),
                                  item: item,
                                  today: today,
                                ),
                                const SizedBox(height: 10),
                              ],
                              OutlinedButton.icon(
                                onPressed: () => context.go(RoutePaths.sell),
                                icon: const Icon(Icons.add),
                                label: const Text('Scan another product'),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              PinnedBottomBar(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Subtotal (${Formatters.unitCount(cart.itemCount)})',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Text(
                        Formatters.amount(cart.total),
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        Formatters.rwf(cart.total),
                        key: const ValueKey('cart-total'),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: cart.items.isEmpty
                        ? null
                        : () => context.push(RoutePaths.sellCheckout),
                    child: const Text('Checkout'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({super.key, required this.item, required this.today});

  final CartItem item;
  final DateTime today;

  /// "Batch AX2407 · exp 14 Oct 2026", or every batch with its units when
  /// the line spans several.
  String get _batchText {
    final allocations = item.allocations;
    if (allocations.length > 1) {
      return 'Batches ${allocations.map((a) => '${a.batchNumber} (${a.quantity})').join(', ')}';
    }
    return 'Batch ${item.batch.batchNumber} · '
        'exp ${Formatters.date(item.batch.expiryDate)}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final cart = context.read<CartCubit>();
    final secondary = textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final bold = textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);
    final inStock = FefoPicker.sortedSellable(
      item.availableBatches,
      today: today,
    ).fold<int>(0, (sum, batch) => sum + batch.quantity);
    final productId = item.product.id;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(item.product.name, style: bold)),
                  const SizedBox(width: 12),
                  Text(Formatters.amount(item.lineTotal), style: bold),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(_batchText, style: secondary),
            Text('${Formatters.rwf(item.unitPrice)} each', style: secondary),
            const SizedBox(height: 8),
            Row(
              children: [
                AppQuantityStepper(
                  quantity: item.quantity,
                  onDecrement: item.quantity > 1
                      ? () => cart.updateQuantity(productId, item.quantity - 1)
                      : null,
                  onIncrement: item.quantity < inStock
                      ? () => cart.updateQuantity(productId, item.quantity + 1)
                      : null,
                ),
                const Spacer(),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: colors.error,
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: () => cart.removeItem(productId),
                  child: const Text('Remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 56, color: colors.primary),
            const SizedBox(height: 16),
            Text('Your cart is empty', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Scan a product to add it to this sale.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => context.go(RoutePaths.sell),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan a product'),
            ),
          ],
        ),
      ),
    );
  }
}
