import 'package:flutter/material.dart';

import '../../../core/l10n.dart';
import '../../../core/money/currency_converter.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/large_text.dart';

/// Income, expenses and net worth at the end of the period, side by side.
class CalendarPeriodSummary extends StatelessWidget {
  const CalendarPeriodSummary({
    super.key,
    required this.income,
    required this.expense,
    required this.netWorth,
    required this.currency,
  });

  final ConvertedTotal income;

  /// Negative.
  final ConvertedTotal expense;
  final ConvertedTotal netWorth;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final line = BorderSide(color: theme.colorScheme.outlineVariant);
    final figures = [
      (l10n.netIncomeIncome, income, AmountStyle.signed),
      (l10n.netIncomeExpenses, expense, AmountStyle.signed),
      (l10n.balanceSheetNetWorth, netWorth, AmountStyle.balance),
    ];
    Widget amount(ConvertedTotal total, AmountStyle style) => AmountText(
      total.amount,
      currency: currency,
      amountStyle: style,
      approximate: total.approximate,
      fit: true,
      style: theme.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600),
    );

    if (isLargeText(context)) {
      // No room for three columns: one line each.
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(border: Border(bottom: line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (label, total, style) in figures)
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(label, style: theme.textTheme.bodySmall),
                  amount(total, style),
                ],
              ),
          ],
        ),
      );
    }
    Widget figure(
      (String, ConvertedTotal, AmountStyle) figure, {
      bool first = false,
    }) => Expanded(
      child: Container(
        padding: EdgeInsetsDirectional.only(start: first ? 0 : 12),
        decoration: BoxDecoration(
          border: first ? null : BorderDirectional(start: line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(figure.$1, style: theme.textTheme.bodySmall),
            amount(figure.$2, figure.$3),
          ],
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: line)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            figure(figures[0], first: true),
            figure(figures[1]),
            figure(figures[2]),
          ],
        ),
      ),
    );
  }
}
