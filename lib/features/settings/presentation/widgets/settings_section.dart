import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A labelled card of rows, e.g. "PHARMACY" or "ALERTS", with dividers
/// between the rows.
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.label, required this.rows});

  final String label;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (index, row) in rows.indexed) ...[
                if (index > 0) const Divider(indent: 16, endIndent: 16),
                row,
              ],
            ],
          ),
        ),
      ],
    );
  }
}
