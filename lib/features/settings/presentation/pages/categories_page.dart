import 'package:flutter/material.dart';

import '../widgets/account_subpage.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_section.dart';

/// Settings > Product categories: each category and how many products it
/// holds, sorted by name.
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AccountSubpage(
      title: 'Product categories',
      builder: (context, account) {
        if (account.categories.isEmpty) {
          return const [
            Padding(
              padding: EdgeInsets.all(24),
              child: Text('No categories yet.', textAlign: TextAlign.center),
            ),
          ];
        }

        final categories = [...account.categories]
          ..sort((a, b) => a.name.compareTo(b.name));

        return [
          SettingsSection(
            label: '${categories.length} CATEGORIES',
            rows: [
              for (final category in categories)
                SettingsRow(
                  title: category.name,
                  detail: category.productCount == 1
                      ? '1 product'
                      : '${category.productCount} products',
                ),
            ],
          ),
        ];
      },
    );
  }
}
