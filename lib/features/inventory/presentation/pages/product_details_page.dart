import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/pinned_bottom_bar.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../pos/domain/entities/pos_batch.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../domain/entities/batch.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/inventory_filter.dart';
import '../cubit/product_details_cubit.dart';
import '../widgets/edit_pricing_dialog.dart';
import '../widgets/fefo_batch_indicator.dart';
import '../widgets/inventory_status_chip.dart';

/// One product: its price, stock and reorder level, and every batch,
/// earliest expiry first.
///
/// Owners can change the price and reorder level and delete the product or
/// a batch. Pharmacists only see the details, as the security rules only
/// let them add batches and lower quantities.
class ProductDetailsPage extends StatelessWidget {
  const ProductDetailsPage({
    super.key,
    required this.canManage,
    this.clock = DateTime.now,
  });

  /// True for the pharmacy owner.
  final bool canManage;

  /// Injected so tests get fixed expiry chips.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final settings = context.select(
      (SettingsCubit cubit) => cubit.state.settings,
    );
    final rules = InventoryRules(
      today: clock(),
      alertDays: settings.expiryAlertDays,
      defaultReorderLevel: settings.lowStockThreshold,
    );

    return BlocBuilder<ProductDetailsCubit, ProductDetailsState>(
      builder: (context, state) {
        final item = state.item;
        return Scaffold(
          appBar: AppBar(
            title: Text(item?.product.name ?? 'Product'),
            actions: [
              if (canManage && item != null)
                _OwnerMenu(item: item, rules: rules, enabled: !state.saving),
            ],
          ),
          body: SafeArea(
            child: switch (state.status) {
              ProductDetailsStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              ProductDetailsStatus.notFound => const _CenteredMessage(
                'This product no longer exists. It may have been deleted on '
                'another phone.',
              ),
              ProductDetailsStatus.failure => _CenteredMessage(
                state.errorMessage ?? '',
                onRetry: () => context.read<ProductDetailsCubit>().start(),
              ),
              ProductDetailsStatus.loaded => _Details(
                item: item!,
                rules: rules,
                canManage: canManage,
                saving: state.saving,
              ),
            },
          ),
          // Anyone can receive stock, owners and pharmacists alike.
          bottomNavigationBar: item == null
              ? null
              : PinnedBottomBar(
                  children: [
                    FilledButton(
                      onPressed: () =>
                          context.push(RoutePaths.addStockFor(item.product.id)),
                      child: const Text('Add stock'),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

enum _OwnerAction { editPricing, delete }

class _OwnerMenu extends StatelessWidget {
  const _OwnerMenu({
    required this.item,
    required this.rules,
    required this.enabled,
  });

  final InventoryItem item;
  final InventoryRules rules;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_OwnerAction>(
      enabled: enabled,
      tooltip: 'Product actions',
      onSelected: (action) => switch (action) {
        _OwnerAction.editPricing => _editPricing(context),
        _OwnerAction.delete => _delete(context),
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _OwnerAction.editPricing,
          child: Text('Edit price and reorder level'),
        ),
        PopupMenuItem(
          value: _OwnerAction.delete,
          child: Text('Delete product'),
        ),
      ],
    );
  }

  Future<void> _editPricing(BuildContext context) async {
    final cubit = context.read<ProductDetailsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final edit = await showEditPricingDialog(
      context,
      product: item.product,
      defaultReorderLevel: rules.defaultReorderLevel,
    );
    if (edit == null) return;
    final error = await cubit.updatePricing(
      sellingPrice: edit.sellingPrice,
      reorderLevel: edit.reorderLevel,
    );
    messenger.showSnackBar(SnackBar(content: Text(error ?? 'Saved')));
  }

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<ProductDetailsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    // The Stock tab's navigator, which holds this page.
    final navigator = Navigator.of(context);
    final confirmed = await _confirm(
      context,
      title: 'Delete ${item.product.name}?',
      message:
          'This deletes the product and its batches. Past sales keep their '
          "records. This can't be undone.",
    );
    if (!confirmed) return;
    final error = await cubit.deleteProduct();
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text('${item.product.name} deleted')),
    );
    navigator.pop();
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.item,
    required this.rules,
    required this.canManage,
    required this.saving,
  });

  final InventoryItem item;
  final InventoryRules rules;
  final bool canManage;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final product = item.product;
    final today = rules.today;
    final expiredUnits = item.expiredUnitsOn(today);
    final details = [
      if (product.form.isNotEmpty) product.form,
      if (product.packSize.isNotEmpty) product.packSize,
    ].join(' · ');
    final reorderLevel = product.reorderLevel == null
        ? '${rules.defaultReorderLevel} units (default)'
        : Formatters.unitCount(product.reorderLevel!);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        InventoryStatusChip(item: item, rules: rules),
                      ],
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        details,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'Barcode',
                      value: product.barcode.isEmpty ? '—' : product.barcode,
                    ),
                    _InfoRow(
                      label: 'Selling price',
                      value: Formatters.rwf(product.sellingPrice),
                    ),
                    _InfoRow(
                      label: 'In stock',
                      value: Formatters.unitCount(item.sellableUnitsOn(today)),
                    ),
                    if (expiredUnits > 0)
                      _InfoRow(
                        label: 'Expired, to remove',
                        value: Formatters.unitCount(expiredUnits),
                      ),
                    _InfoRow(label: 'Reorder level', value: reorderLevel),
                    _InfoRow(
                      label: 'Stock value at cost',
                      value: Formatters.rwf(item.stockValue),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(
                'BATCHES (${item.batchesInStock.length})',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            if (item.batchesInStock.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No stock. Received batches show here.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (index, batch)
                        in item.batchesInStock.indexed) ...[
                      if (index > 0) const Divider(indent: 16),
                      _BatchRow(
                        batch: batch,
                        item: item,
                        rules: rules,
                        canDelete: canManage && !saving,
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _BatchRow extends StatelessWidget {
  const _BatchRow({
    required this.batch,
    required this.item,
    required this.rules,
    required this.canDelete,
  });

  final Batch batch;
  final InventoryItem item;
  final InventoryRules rules;
  final bool canDelete;

  static PosBatch _toPosBatch(Batch batch) => PosBatch(
    id: batch.id,
    batchNumber: batch.batchNumber,
    expiryDate: batch.expiryDate,
    quantity: batch.quantity,
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final today = rules.today;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Batch ${batch.batchNumber}',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Expires ${Formatters.date(batch.expiryDate)} · '
                  '${Formatters.unitCount(batch.quantity)} · '
                  'cost ${Formatters.rwf(batch.costPrice)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    StatusChip.expiry(
                      expiryDate: batch.expiryDate,
                      today: today,
                      alertDays: rules.alertDays,
                    ),
                    if (!batch.isExpiredOn(today))
                      FefoBatchIndicator(
                        batch: _toPosBatch(batch),
                        batches: [
                          for (final other in item.batches) _toPosBatch(other),
                        ],
                        today: today,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (canDelete)
            IconButton(
              tooltip: 'Delete batch ${batch.batchNumber}',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(context),
            ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<ProductDetailsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await _confirm(
      context,
      title: 'Delete batch ${batch.batchNumber}?',
      message:
          'Its ${Formatters.unitCount(batch.quantity)} leave the stock. To '
          'record expired or damaged stock, use Remove stock instead.',
    );
    if (!confirmed) return;
    final error = await cubit.deleteBatch(batch.id);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? 'Batch ${batch.batchNumber} deleted')),
    );
  }
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage(this.message, {this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}
