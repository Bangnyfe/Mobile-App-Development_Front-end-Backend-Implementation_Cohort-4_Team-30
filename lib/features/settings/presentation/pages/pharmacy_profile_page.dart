import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/account_subpage.dart';
import '../widgets/settings_section.dart';

/// Settings > Pharmacy profile: the pharmacy's name, location and contact.
class PharmacyProfilePage extends StatelessWidget {
  const PharmacyProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AccountSubpage(
      title: 'Pharmacy profile',
      builder: (context, account) {
        final pharmacy = account.pharmacy;
        return [
          SettingsSection(
            label: 'DETAILS',
            rows: [
              _DetailRow(label: 'Name', value: pharmacy.name),
              _DetailRow(label: 'District', value: pharmacy.district),
              _DetailRow(label: 'City', value: pharmacy.city),
              _DetailRow(label: 'Address', value: pharmacy.address ?? '—'),
              _DetailRow(label: 'Phone', value: pharmacy.phone ?? '—'),
            ],
          ),
        ];
      },
    );
  }
}

/// A grey label above its value, so long addresses wrap instead of
/// squeezing the label.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
