import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/removable_product.dart';

/// One selectable batch on "Choose batch": number, expiry chip, expiry
/// date and units in stock. The selected batch has a teal border.
class BatchOptionCard extends StatelessWidget {
  const BatchOptionCard({
    super.key,
    required this.batch,
    required this.selected,
    required this.today,
    required this.alertDays,
    required this.onTap,
  });

  final RemovableBatch batch;
  final bool selected;
  final DateTime today;
  final int alertDays;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final empty = batch.quantity <= 0;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.primaryContainer : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: empty ? null : onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              batch.batchNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            StatusChip.expiry(
                              expiryDate: batch.expiryDate,
                              today: today,
                              alertDays: alertDays,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${batch.isExpiredOn(today) ? 'Expired' : 'Expires'} '
                          '${Formatters.date(batch.expiryDate)} · '
                          '${Formatters.unitCount(batch.quantity)} in stock',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
