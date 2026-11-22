import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// "Step 1 of 2 · Choose batch" with a progress bar.
class RemoveStockStepHeader extends StatelessWidget {
  const RemoveStockStepHeader({
    super.key,
    required this.step,
    required this.title,
  });

  /// 1 or 2.
  final int step;
  final String title;

  static const totalSteps = 2;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step $step of $totalSteps · $title',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: step / totalSteps,
            minHeight: 4,
            backgroundColor: AppColors.border,
          ),
        ),
      ],
    );
  }
}
