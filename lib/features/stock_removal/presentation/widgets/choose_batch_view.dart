import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/removable_product.dart';
import '../cubit/remove_stock_cubit.dart';
import 'batch_option_card.dart';
import 'bottom_action_bar.dart';
import 'quantity_stepper.dart';
import 'remove_stock_step_header.dart';

class ChooseBatchView extends StatelessWidget {
  const ChooseBatchView({
    super.key,
    required this.state,
    required this.today,
    required this.alertDays,
  });

  final RemoveStockState state;
  final DateTime today;
  final int alertDays;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RemoveStockCubit>();
    final product = state.product;
    final batch = state.batch;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const RemoveStockStepHeader(step: 1, title: 'Choose batch'),
              const SizedBox(height: 16),
              if (product == null) ...[
                TextFormField(
                  initialValue: state.query,
                  onChanged: cubit.search,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Search product name or barcode',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                if (state.visibleProducts.isEmpty)
                  _EmptyMessage(
                    state.products.isEmpty
                        ? 'There is no stock to remove yet.'
                        : 'No products match "${state.query.trim()}".',
                  )
                else
                  for (final item in state.visibleProducts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ProductTile(
                        product: item,
                        onTap: () => cubit.selectProduct(item.id),
                      ),
                    ),
              ] else ...[
                _SelectedProductCard(
                  product: product,
                  onChange: cubit.clearProduct,
                ),
                const SizedBox(height: 20),
                const _SectionTitle('Choose batch'),
                const SizedBox(height: 8),
                for (final option in product.batches)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: BatchOptionCard(
                      batch: option,
                      selected: option.id == state.batchId,
                      today: today,
                      alertDays: alertDays,
                      onTap: () => cubit.selectBatch(option.id),
                    ),
                  ),
                if (batch != null) ...[
                  const SizedBox(height: 12),
                  QuantityStepper(
                    quantity: state.quantity,
                    max: batch.quantity,
                    onDecrement: cubit.decrement,
                    onIncrement: cubit.increment,
                    onRemoveAll: cubit.removeAll,
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'You will choose a reason on the next step.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        BottomActionBar(
          children: [
            FilledButton(
              onPressed: state.canContinue ? cubit.goToReason : null,
              child: const Text('Continue'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onTap});

  final RemovableProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (product.details.isNotEmpty) product.details,
      '${Formatters.unitCount(product.totalUnits)} in stock',
    ].join(' · ');

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: const Icon(
          Icons.medication_outlined,
          color: AppColors.primary,
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _SelectedProductCard extends StatelessWidget {
  const _SelectedProductCard({required this.product, required this.onChange});

  final RemovableProduct product;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.medication_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${Formatters.unitCount(product.totalUnits)} in stock',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onChange, child: const Text('Change')),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
