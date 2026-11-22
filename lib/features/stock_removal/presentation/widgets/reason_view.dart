import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/removal_reason.dart';
import '../cubit/remove_stock_cubit.dart';
import 'bottom_action_bar.dart';
import 'reason_option_tile.dart';
import 'remove_stock_step_header.dart';

class ReasonView extends StatelessWidget {
  const ReasonView({super.key, required this.state, required this.today});

  final RemoveStockState state;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RemoveStockCubit>();
    final product = state.product!;
    final batch = state.batch!;
    final saving = state.submitStatus == SubmitStatus.submitting;
    final expired = batch.isExpiredOn(today);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const RemoveStockStepHeader(step: 2, title: 'Reason'),
              const SizedBox(height: 16),
              if (state.fromNotification && expired) ...[
                _NotificationBanner(
                  'From notification: batch ${batch.batchNumber} expired on '
                  '${Formatters.date(batch.expiryDate)} and is still on the '
                  'shelf.',
                ),
                const SizedBox(height: 12),
              ],
              _SummaryCard(
                productName: product.name,
                batchLine:
                    'Batch ${batch.batchNumber} · '
                    '${expired ? 'expired' : 'expires'} '
                    '${Formatters.date(batch.expiryDate)}',
                quantity: state.quantity,
                costValue: state.costValue,
              ),
              const SizedBox(height: 20),
              const Text(
                'Reason (required)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              for (final reason in RemovalReason.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ReasonOptionTile(
                    reason: reason,
                    selected: state.reason == reason,
                    suggested: state.suggestedReason == reason,
                    onTap: saving ? null : () => cubit.selectReason(reason),
                  ),
                ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: state.note,
                onChanged: cubit.setNote,
                enabled: !saving,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: state.reason?.requiresNote ?? false
                      ? 'Note (required)'
                      : 'Note (optional)',
                  hintText: 'Add details, for example what happened',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        BottomActionBar(
          children: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: AppColors.onPrimary,
              ),
              onPressed: state.canSubmit ? cubit.submit : null,
              child: saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(
                      state.reason == null
                          ? 'Choose a reason to continue'
                          : 'Remove ${Formatters.unitCount(state.quantity)}',
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NotificationBanner extends StatelessWidget {
  const _NotificationBanner(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dangerContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: AppColors.danger,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.productName,
    required this.batchLine,
    required this.quantity,
    required this.costValue,
  });

  final String productName;
  final String batchLine;
  final int quantity;
  final int costValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  batchLine,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '−${Formatters.unitCount(quantity)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger,
                ),
              ),
              Text(
                '${Formatters.rwf(costValue)} at cost',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
