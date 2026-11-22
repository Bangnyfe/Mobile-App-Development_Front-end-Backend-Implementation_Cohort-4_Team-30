import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../stock_removal/domain/entities/removal_reason.dart';
import '../../domain/stock_report.dart';

/// A headline number on a report, e.g. "Stock on hand at cost".
class ReportStatCard extends StatelessWidget {
  const ReportStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.caption,
    this.danger = false,
  });

  final String title;
  final String value;
  final String caption;

  /// Red tint for losses (removed or expired stock).
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final foreground = danger ? AppColors.danger : AppColors.textPrimary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: danger ? AppColors.dangerContainer : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: danger ? AppColors.dangerContainer : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 13, color: foreground),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: foreground,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: TextStyle(
              fontSize: 12,
              color: danger ? AppColors.danger : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// "STOCK REMOVALS     12" above a list.
class ReportSectionHeader extends StatelessWidget {
  const ReportSectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        children: [
          Expanded(child: Text(title.toUpperCase(), style: style)),
          if (trailing != null) Text(trailing!, style: style),
        ],
      ),
    );
  }
}

/// The reason for a removal as a coloured chip.
class ReasonChip extends StatelessWidget {
  const ReasonChip(this.reason, {super.key});

  final RemovalReason reason;

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      label: reason.label,
      tone: switch (reason) {
        RemovalReason.expired || RemovalReason.recalled => StatusTone.danger,
        RemovalReason.damaged ||
        RemovalReason.lostOrMissing => StatusTone.warning,
        RemovalReason.returnedToSupplier ||
        RemovalReason.other => StatusTone.info,
      },
    );
  }
}

/// Grey text in the middle of an empty list.
class ReportEmptyMessage extends StatelessWidget {
  const ReportEmptyMessage(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

/// Bars of expired stock removed per month ("Expired stock by
/// month, at cost"). Drawn with plain boxes, so no chart package is needed.
class MonthBarChart extends StatelessWidget {
  const MonthBarChart({super.key, required this.totals});

  final List<MonthTotal> totals;

  static const _barAreaHeight = 120.0;
  static final _monthLabel = DateFormat('MMM', 'en_US');

  @override
  Widget build(BuildContext context) {
    final highest = totals.fold(0, (max, t) => t.value > max ? t.value : max);
    final description = totals
        .map((t) => '${_monthLabel.format(t.month)} ${Formatters.rwf(t.value)}')
        .join(', ');

    return Semantics(
      label: 'Expired stock removed by month: $description',
      excludeSemantics: true,
      child: SizedBox(
        height: _barAreaHeight + 40,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final total in totals)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (total.value > 0)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _thousands(total.value),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      const SizedBox(height: 2),
                      Container(
                        height: highest == 0
                            ? 2
                            : (total.value / highest * _barAreaHeight)
                                  .clamp(2, _barAreaHeight)
                                  .toDouble(),
                        decoration: BoxDecoration(
                          color: total.value > 0
                              ? AppColors.danger
                              : AppColors.border,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _monthLabel.format(total.month),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _thousands(int value) {
    if (value < 1000) return '$value';
    final thousands = value / 1000;
    return thousands >= 100
        ? '${thousands.round()}k'
        : '${thousands.toStringAsFixed(1).replaceAll('.0', '')}k';
  }
}