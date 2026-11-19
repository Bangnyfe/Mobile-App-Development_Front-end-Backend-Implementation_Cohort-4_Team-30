import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AuthIconTile extends StatelessWidget {
  const AuthIconTile({
    super.key,
    this.icon = Icons.add,
    this.filled = true,
    this.size = 44,
  });

  final IconData icon;

  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? AppColors.primary : AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(size * 0.27),
      ),
      child: Icon(
        icon,
        size: size * 0.55,
        color: filled ? AppColors.onPrimary : AppColors.primary,
      ),
    );
  }
}

/// Icon, title and one-line explanation at the top of each auth screen.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.tile = const AuthIconTile(),
  });

  final String title;
  final String subtitle;
  final Widget tile;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tile,
        const SizedBox(height: 20),
        Text(
          title,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
