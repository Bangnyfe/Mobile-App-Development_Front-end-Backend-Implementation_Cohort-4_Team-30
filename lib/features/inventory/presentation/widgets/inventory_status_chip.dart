import 'package:flutter/material.dart';

import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/inventory_filter.dart';

/// The most urgent thing about a product, as one chip: expired stock on the
/// shelf, then low stock, then a batch expiring soon. Nothing when all is
/// well.
class InventoryStatusChip extends StatelessWidget {
  const InventoryStatusChip({
    super.key,
    required this.item,
    required this.rules,
  });

  final InventoryItem item;
  final InventoryRules rules;

  @override
  Widget build(BuildContext context) {
    if (rules.matches(item, InventoryFilter.expired)) {
      return const StatusChip(label: 'Expired stock', tone: StatusTone.danger);
    }
    if (rules.matches(item, InventoryFilter.lowStock)) {
      return const StatusChip.lowStock();
    }
    final next = item.nextToExpireOn(rules.today);
    if (next != null && rules.matches(item, InventoryFilter.expiringSoon)) {
      return StatusChip.expiry(
        expiryDate: next.expiryDate,
        today: rules.today,
        alertDays: rules.alertDays,
      );
    }
    return const SizedBox.shrink();
  }
}
