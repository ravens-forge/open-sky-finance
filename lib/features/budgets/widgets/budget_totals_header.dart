import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/money/format_money.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/budget_bar.dart';
import '../../../core/widgets/info_tooltip.dart';
import '../../../core/widgets/large_text.dart';
import '../models/budget_overview.dart';

class BudgetTotalsHeader extends StatelessWidget {
  const BudgetTotalsHeader({
    super.key,
    required this.overview,
    required this.daysInMonth,
    this.day,
  });

  final BudgetOverview overview;
  final int daysInMonth;
  final int? day;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final finance = FinanceColors.of(context);
    final rule = BorderSide(color: theme.colorScheme.outlineVariant);
    final percent = NumberFormat.decimalPercentPattern(
      locale: l10n.localeName,
      decimalDigits: 1,
    );
    final spent = percent.format(overview.spent / overview.budgeted);
    final elapsed = day == null ? null : day! / daysInMonth;
    // With large text the three figures stack instead of sharing a line.
    final large = isLargeText(context);

    Widget figure(
      String label,
      int micros, {
      bool approximate = false,
      Color? color,
      Widget? info,
      bool first = false,
    }) {
      final column = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // As tall as the info icon in every column, so the labels line up.
          SizedBox(
            height: large ? null : 44,
            child: Row(
              children: [
                Flexible(child: Text(label, style: theme.textTheme.bodySmall)),
                ?info,
              ],
            ),
          ),
          AmountText(
            micros,
            currency: overview.currency,
            amountStyle: AmountStyle.balance,
            approximate: approximate,
            style: theme.textTheme.rowAmount.copyWith(color: color),
            fit: true,
          ),
        ],
      );
      if (large) return column;
      return Expanded(
        // The column with the info icon is a little wider, for its label.
        flex: info == null ? 5 : 6,
        child: Container(
          padding: EdgeInsetsDirectional.only(start: first ? 0 : 12),
          decoration: BoxDecoration(
            border: BorderDirectional(start: first ? BorderSide.none : rule),
          ),
          child: column,
        ),
      );
    }

    final figures = [
      figure(l10n.budgetBudgeted, overview.budgeted, first: true),
      figure(
        l10n.budgetSpent,
        overview.spent,
        approximate: overview.approximate,
      ),
      figure(
        l10n.budgetRemaining,
        overview.remaining,
        approximate: overview.approximate,
        // Negative amounts are drawn in `expense` by [AmountText].
        color: overview.remaining > 0 ? finance.income : null,
        info: InfoTooltip(
          label: l10n.budgetRemainingInfoLabel,
          text: l10n.budgetRemainingInfo,
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(border: Border(bottom: rule)),
          child: large
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: figures,
                )
              : IntrinsicHeight(child: Row(children: figures)),
        ),
        const SizedBox(height: 16),
        BudgetBar(
          spentMicros: overview.spent,
          budgetMicros: overview.budgeted,
          height: 14,
          marker: elapsed,
        ),
        const SizedBox(height: 12),
        Text(
          elapsed == null
              ? l10n.budgetSpentPercent(spent)
              : l10n.budgetSpentPercentToday(
                  spent,
                  day!,
                  daysInMonth,
                  percent.format(elapsed),
                ),
          style: theme.textTheme.bodySmall,
        ),
        if (overview.notIncluded.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.assetsAccountsNotIncluded(
                [
                  for (final MapEntry(key: currency, value: micros)
                      in overview.notIncluded.entries)
                    formatMoney(
                      micros,
                      currency: currency,
                      locale: l10n.localeName,
                    ),
                ].join(', '),
              ),
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
