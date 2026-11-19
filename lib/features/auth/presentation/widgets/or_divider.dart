import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// "──── or ────" between email sign-in and Google sign-in.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: TextStyle(color: AppColors.textSecondary)),
        ),
        Expanded(child: Divider()),
      ],
    );
  }
}