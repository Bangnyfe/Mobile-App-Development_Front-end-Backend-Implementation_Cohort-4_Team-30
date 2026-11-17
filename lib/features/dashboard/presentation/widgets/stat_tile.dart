import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A small summary tile (label, big number, caption) from the Home grid.
///
/// Set [isAlert] for the red "Expired" tile.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
    this.isAlert = false,
  });

  final String label;
  final String value;
  final String caption;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = isAlert ? AppColors.danger : AppColors.textPrimary;
    final muted = isAlert ? AppColors.danger : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAlert ? AppColors.dangerContainer : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAlert
              ? AppColors.danger.withValues(alpha: 0.25)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.bodySmall?.copyWith(color: muted)),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(caption, style: textTheme.bodySmall?.copyWith(color: muted)),
        ],
      ),
    );
  }
}
