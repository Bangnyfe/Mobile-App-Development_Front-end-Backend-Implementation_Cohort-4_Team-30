import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/expiry_status.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_quantity_stepper.dart';
import '../../../../core/widgets/app_radio_card.dart';
import '../../../../core/widgets/pinned_bottom_bar.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../scanner/domain/entities/found_product.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../domain/entities/pos_batch.dart';
import '../cubit/batch_pick_cubit.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';

/// A scanned product: choose the batch (FEFO suggested) and how many to
/// add to the cart.
class ProductFoundPage extends StatelessWidget {
  const ProductFoundPage({
    super.key,
    required this.found,
    this.clock = DateTime.now,
  });

  final FoundProduct found;

  /// For tests; the app uses the real time.
  final DateTime Function() clock;

  void _addToCart(BuildContext context, BatchPickState pick) {
    final cart = context.read<CartCubit>();
    final batch = pick.selected;
    if (batch == null || !pick.canAdd) return;

    // The cart allocates FEFO across the batches it's given. Giving it the
    // chosen batch makes the sale come from that batch, as the note says.
    // If the product is already in the cart, its batches stay available.
    final existing = cart.state.items
        .where((item) => item.product.id == found.product.id)
        .firstOrNull;
    final batches = {...?existing?.availableBatches, batch}.toList();

    final errorsBefore = cart.state.errorCount;
    cart.addItem(
      product: found.product,
      batches: batches,
      quantity: pick.quantity,
    );
    if (cart.state.errorCount == errorsBefore) context.go(RoutePaths.sellCart);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final today = clock();
    final alertDays = context.select(
      (SettingsCubit cubit) => cubit.state.settings.expiryAlertDays,
    );

    return BlocListener<CartCubit, CartState>(
      listenWhen: (previous, current) =>
          current.errorCount != previous.errorCount && current.error != null,
      listener: (context, cart) => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(cart.error!))),
      child: BlocBuilder<BatchPickCubit, BatchPickState>(
        builder: (context, pick) {
          final picker = context.read<BatchPickCubit>();
          final selected = pick.selected;

          return Scaffold(
            appBar: AppBar(title: const Text('Product found')),
            body: Column(
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        children: [
                          _ProductCard(found: found),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'CHOOSE BATCH',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              Text(
                                'Earliest expiry suggested',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (pick.sellable.isEmpty)
                            Text(
                              'Nothing to sell: every batch of this product '
                              'is expired or out of stock.',
                              style: textTheme.bodyMedium,
                            )
                          else
                            for (final batch in pick.sellable) ...[
                              AppRadioCard(
                                key: ValueKey('batch-${batch.id}'),
                                selected: batch.id == selected?.id,
                                onTap: () => picker.select(batch.id),
                                child: _BatchDetails(
                                  batch: batch,
                                  today: today,
                                  alertDays: alertDays,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          if (selected != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Quantity',
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '${Formatters.rwf(found.product.sellingPrice)} each',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AppQuantityStepper(
                                  quantity: pick.quantity,
                                  onDecrement: pick.quantity > 1
                                      ? picker.decrement
                                      : null,
                                  onIncrement: pick.quantity < pick.max
                                      ? picker.increment
                                      : null,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _StockNote(pick: pick, batch: selected),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                PinnedBottomBar(
                  children: [
                    FilledButton(
                      onPressed: pick.canAdd
                          ? () => _addToCart(context, pick)
                          : null,
                      child: Text(
                        'Add to cart · '
                        '${Formatters.rwf(found.product.sellingPrice * pick.quantity)}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.found});

  final FoundProduct found;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final secondary = textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.medication_outlined,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    found.product.name,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (found.details.isNotEmpty)
                    Text(found.details, style: secondary),
                  Text('Barcode ${found.product.barcode}', style: secondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Batch number, days-left chip, expiry date and units in stock.
class _BatchDetails extends StatelessWidget {
  const _BatchDetails({
    required this.batch,
    required this.today,
    required this.alertDays,
  });

  final PosBatch batch;
  final DateTime today;
  final int alertDays;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = expiryStatusFor(
      batch.expiryDate,
      today: today,
      alertDays: alertDays,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              batch.batchNumber,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            StatusChip(
              label: _timeLeft(
                daysUntilExpiry(batch.expiryDate, today: today),
                status,
              ),
              tone: status == ExpiryStatus.inDate
                  ? StatusTone.success
                  : StatusTone.warning,
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Expires ${Formatters.date(batch.expiryDate)} · '
          '${batch.quantity} in stock',
          style: textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// "Expires today", "1 day left" or "19 days left" within the expiry
  /// alert period (warning tone); "17 months" past it, as in the design.
  static String _timeLeft(int days, ExpiryStatus status) {
    if (days <= 0) return 'Expires today';
    if (status == ExpiryStatus.inDate && days >= 60) {
      return '${days ~/ 30} months';
    }
    return days == 1 ? '1 day left' : '$days days left';
  }
}

/// "Stock will drop from 18 to 16 in batch AX2407 when the sale is
/// confirmed."
class _StockNote extends StatelessWidget {
  const _StockNote({required this.pick, required this.batch});

  final BatchPickState pick;
  final PosBatch batch;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final full = pick.max == 0;
    final from = batch.quantity - pick.reserved;
    final text = full
        ? 'All ${batch.quantity} units of batch ${batch.batchNumber} are '
              'already in the cart.'
        : 'Stock will drop from $from to ${pick.stockAfter} in batch '
              '${batch.batchNumber} when the sale is confirmed.';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            full ? Icons.info_outline : Icons.check,
            size: 20,
            color: colors.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
