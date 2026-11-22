import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// "Quantity to remove": minus, the number, plus, and "Remove all N".
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.max,
    required this.onDecrement,
    required this.onIncrement,
    required this.onRemoveAll,
  });

  final int quantity;
  final int max;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onRemoveAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Quantity to remove',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            IconButton.outlined(
              tooltip: 'Remove one less',
              onPressed: quantity > 1 ? onDecrement : null,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 48,
              child: Text(
                '$quantity',
                key: const ValueKey('removal-quantity'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton.outlined(
              tooltip: 'Remove one more',
              onPressed: quantity < max ? onIncrement : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              'Up to $max in this batch',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            ActionChip(
              label: Text('Remove all $max'),
              onPressed: quantity < max ? onRemoveAll : null,
            ),
          ],
        ),
      ],
    );
  }
}
