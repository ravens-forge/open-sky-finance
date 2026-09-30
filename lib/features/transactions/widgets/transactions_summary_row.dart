import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/l10n.dart';
import '../../../core/money/currency_converter.dart';
import '../../../core/money/format_money.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/large_text.dart';
import '../../../data/models/income_expense.dart';

/// Income, expenses and net of the period, converted to the main currency.
class TransactionsSummaryRow extends StatelessWidget {
  const TransactionsSummaryRow({
    super.key,
    required this.totals,
    required this.converter,
  });

  final IncomeExpense totals;
  final CurrencyConverter converter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final net = converter.convert(totals.net);

    final rule = BorderSide(color: theme.colorScheme.outlineVariant);
    // With large text the three figures stack instead of sharing a line.
    final large = isLargeText(context);
    Widget total(
      String label,
      ConvertedTotal value,
      AmountStyle style, {
      bool first = false,
    }) {
      final figure = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          AmountText(
            value.amount,
            currency: converter.mainCurrency,
            amountStyle: style,
            approximate: value.approximate,
            style: theme.textTheme.rowAmount,
            fit: true,
          ),
        ],
      );
      if (large) return figure;
      return Expanded(
        child: Container(
          padding: EdgeInsetsDirectional.only(start: first ? 0 : 12),
          decoration: BoxDecoration(
            border: BorderDirectional(start: first ? BorderSide.none : rule),
          ),
          child: figure,
        ),
      );
    }

    final figures = [
      total(
        l10n.transactionsIncome,
        converter.convert(totals.income),
        AmountStyle.signed,
        first: true,
      ),
      total(
        l10n.transactionsExpenses,
        converter.convert(totals.expense),
        AmountStyle.signed,
      ),
      total(l10n.transactionsNet, net, AmountStyle.balance),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(border: Border(bottom: rule)),
          child: large
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: figures,
                )
              : IntrinsicHeight(child: Row(children: figures)),
        ),
        if (net.notIncluded.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.assetsAccountsNotIncluded(
                [
                  for (final MapEntry(key: currency, value: micros)
                      in net.notIncluded.entries)
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
