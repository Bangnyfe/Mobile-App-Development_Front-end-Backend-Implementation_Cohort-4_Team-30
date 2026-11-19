import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/expiry_status.dart';

/// Colour pairs for [StatusChip]. Each pair passes 4.5:1 contrast.
enum StatusTone {
  success(AppColors.success, AppColors.successContainer),
  warning(AppColors.warning, AppColors.warningContainer),
  danger(AppColors.danger, AppColors.dangerContainer),
  info(AppColors.info, AppColors.infoContainer);

  const StatusTone(this.foreground, this.background);

  final Color foreground;
  final Color background;
}

/// Small rounded label used on batch cards, product rows and notifications,
/// e.g. "19 days", "In date", "Low stock", "Expired".
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.tone});

  /// Chip for a batch's expiry date, using the alert period from Settings.
  factory StatusChip.expiry({
    Key? key,
    required DateTime expiryDate,
    required DateTime today,
    required int alertDays,
  }) {
    final status = expiryStatusFor(
      expiryDate,
      today: today,
      alertDays: alertDays,
    );
    return StatusChip(
      key: key,
      label: expiryLabel(expiryDate, today: today, alertDays: alertDays),
      tone: switch (status) {
        ExpiryStatus.expired => StatusTone.danger,
        ExpiryStatus.expiringSoon => StatusTone.warning,
        ExpiryStatus.inDate => StatusTone.success,
      },
    );
  }

  const StatusChip.lowStock({super.key})
    : label = 'Low stock',
      tone = StatusTone.warning;

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: tone.foreground,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
