import 'package:flutter/material.dart';

/// Temporary screen shown for a tab until its owner's real page is merged.
class FeaturePlaceholderPage extends StatelessWidget {
  const FeaturePlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title is coming soon',
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
