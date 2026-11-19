import 'package:flutter/material.dart';

import '../../../../core/widgets/status_chip.dart';
import '../../../pos/domain/entities/pos_batch.dart';
import '../../../pos/domain/services/fefo_picker.dart';

/// Shows "Expired" on an expired batch, or "Sell first" on the batch that
/// FEFO would sell next. Shows nothing for any other batch.
class FefoBatchIndicator extends StatelessWidget {
  const FefoBatchIndicator({
    super.key,
    required this.batch,
    required this.batches,
    required this.today,
  });

  final PosBatch batch;
  final List<PosBatch> batches;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    if (batch.isExpiredOn(today)) {
      return const StatusChip(label: 'Expired', tone: StatusTone.danger);
    }

    final sellFirst =
        batch.isSellableOn(today) &&
        FefoPicker.pick(batches, today: today)?.id == batch.id;
    if (sellFirst) {
      return const StatusChip(label: 'Sell first', tone: StatusTone.success);
    }

    return const SizedBox.shrink();
  }
}
