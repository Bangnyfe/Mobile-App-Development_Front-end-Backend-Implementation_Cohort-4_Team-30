import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';

/// The teal "Today's sales" card at the top of the Home screen.
class TodaySalesCard extends StatelessWidget {
  const TodaySalesCard({
    super.key,
    required this.total,
    required this.saleCount,
    required this.changeVsYesterday,
  });

  final int total;
  final int saleCount;

  /// Null when there is nothing to compare against.
  final double? changeVsYesterday;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mutedWhite = AppColors.onPrimary.withValues(alpha: 0.85);
    final salesLabel = saleCount == 1 ? '1 sale' : '$saleCount sales';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's sales",
            style: textTheme.bodyMedium?.copyWith(color: mutedWhite),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Formatters.rwf(total),
              style: textTheme.headlineMedium?.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              if (changeVsYesterday != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    Formatters.percentChange(changeVsYesterday!),
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Text(
                changeVsYesterday != null
                    ? 'vs yesterday · $salesLabel'
                    : salesLabel,
                style: textTheme.bodySmall?.copyWith(color: mutedWhite),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
