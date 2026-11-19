import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// One row in a Settings card: a title, an optional subtitle, and either a
/// value (shown in bold teal), a custom trailing widget such as a switch,
/// or a chevron when the row opens another page.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.detail,
    this.trailing,
    this.showChevron = false,
    this.onTap,
  });

  final String title;
  final String? subtitle;

  /// Highlighted value, e.g. "20 units".
  final String? value;

  /// Quiet grey text before the chevron, e.g. "3 people".
  final String? detail;

  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        // Keeps every row at least a 48dp tap target.
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 12),
                Text(
                  value!,
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (detail != null) ...[
                const SizedBox(width: 12),
                Text(
                  detail!,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              if (showChevron) ...[
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
