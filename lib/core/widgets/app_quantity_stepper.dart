import 'package:flutter/material.dart';

/// Minus, the quantity, plus, in a bordered box. Used on Product found and
/// on each cart line. Each button is a 48dp tap target; pass null to
/// disable one (e.g. minus at 1, plus at the stock limit).
class AppQuantityStepper extends StatelessWidget {
  const AppQuantityStepper({
    super.key,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'One less',
            onPressed: onDecrement,
            icon: const Icon(Icons.remove),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 32),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'One more',
            onPressed: onIncrement,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
