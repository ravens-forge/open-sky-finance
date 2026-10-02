import 'package:flutter/material.dart';

import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../data/enums/transaction_type.dart';
import 'calendar_marker.dart';

/// What the markers under the days mean.
class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final finance = FinanceColors.of(context);
    final style = Theme.of(context).textTheme.bodySmall!
        .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    Widget item(String label, Color color, {bool ring = false}) => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 5,
      children: [
        CalendarMarker(color: color, ring: ring, size: 7),
        Text(label, style: style),
      ],
    );

    return Container(
      padding: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        children: [
          item(TransactionType.income.label(l10n), finance.income),
          item(TransactionType.expense.label(l10n), finance.expense),
          item(TransactionType.transfer.label(l10n), finance.transfer),
          item(l10n.calendarLegendReminder, finance.warning, ring: true),
        ],
      ),
    );
  }
}
