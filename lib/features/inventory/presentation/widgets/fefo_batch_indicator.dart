import 'package:flutter/material.dart';

import '../../../pos/domain/entities/pos_batch.dart';
import '../../../pos/domain/services/fefo_picker.dart';

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
    final expired = batch.isExpiredOn(today);
    final sellable = batch.isSellableOn(today);
    final sellFirst =
        sellable && FefoPicker.pick(batches, today: today)?.id == batch.id;

    return Row(
      children: [
        if (expired)
          const Chip(
            label: Text('EXPIRED'),
            backgroundColor: Color(0xFFFFE4E6),
          ),
        if (sellFirst)
          const Chip(
            label: Text('SELL FIRST'),
            backgroundColor: Color(0xFFD1FAE5),
          ),
      ],
    );
  }
}
