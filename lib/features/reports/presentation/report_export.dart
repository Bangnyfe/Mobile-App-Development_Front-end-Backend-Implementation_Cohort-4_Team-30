import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/formatters.dart';
import 'cubit/stock_reports_cubit.dart';

/// Plain-text versions of the stock reports, for "Export report": copied
/// to the clipboard so they can be pasted into a message or document.

String inventoryReportText(StockReportsState state) {
  final month = state.thisMonthTotals;
  return [
    'Inventory report · ${Formatters.date(state.today)}',
    'Stock on hand at cost: ${Formatters.rwf(state.stockValue)} '
        '(${state.productCount} products)',
    'Removed this month: ${Formatters.unitCount(month.units)}, '
        '${Formatters.rwf(month.value)} (${month.count} removals)',
    '',
    'Stock removals:',
    for (final removal in state.removals)
      '- ${Formatters.date(removal.createdAt)} · ${removal.productName} · '
          'batch ${removal.batchNumber} · '
          '${Formatters.unitCount(removal.quantity)} · '
          '${removal.reason.label} · ${Formatters.rwf(removal.costValue)} · '
          '${removal.removedByName}',
  ].join('\n');
}

String expiryWasteReportText(StockReportsState state) {
  final removed = state.expiredRemovedTotals;
  return [
    'Expiry and waste report · ${state.period.label} · '
        '${Formatters.date(state.today)}',
    'Expired stock removed: ${Formatters.rwf(removed.value)} '
        '(${removed.count} batches)',
    'Expired, still on the shelf: '
        '${Formatters.rwf(state.expiredOnShelfValue)}',
    '',
    'Expired, still on the shelf:',
    for (final line in state.expiredStillOnShelf)
      '- ${line.productName} · batch ${line.batchNumber} · '
          '${Formatters.unitCount(line.units)} · expired '
          '${Formatters.date(line.expiryDate)} · ${Formatters.rwf(line.value)}',
  ].join('\n');
}

/// Copies [text] and confirms with a SnackBar.
Future<void> copyReport(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text('Report copied. Paste it into a message or document.'),
      ),
    );
}
