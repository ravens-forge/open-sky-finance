import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../app/default_currency.dart';
import '../../../app/theme.dart';
import '../../../core/l10n.dart';
import '../../../core/money/currency_order.dart';
import '../../../core/money/format_money.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/currency_totals.dart';
import '../../../core/widgets/large_text.dart';
import '../../../data/models/income_expense.dart';

/// Income, expenses and net of the period, one line per currency (the
/// default currency first, never converted); past three currencies the rest
/// fold into "+N more currencies".
class TransactionsSummaryRow extends HookConsumerWidget {
  const TransactionsSummaryRow({super.key, required this.totals});

  final IncomeExpense totals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final expanded = useState(false);
    final fallback = ref.watch(defaultCurrencyProvider).value;
    if (fallback == null) return const SizedBox.shrink();
    final net = totals.net;
    final all = orderCurrencies(net.keys, fallback);
    final shared = sharedSymbols(all, l10n.localeName);
    final currencies = all.isEmpty
        ? [fallback]
        : expanded.value
        ? all
        : all.take(foldedCurrencies).toList();

    final rule = BorderSide(color: theme.colorScheme.outlineVariant);
    // With large text the three figures stack instead of sharing a line.
    final large = isLargeText(context);
    Widget total(
      String label,
      Map<String, int> amounts,
      AmountStyle style, {
      bool first = false,
    }) {
      final figure = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          for (final currency in currencies)
            AmountText(
              amounts[currency] ?? 0,
              currency: currency,
              amountStyle: style,
              style: theme.textTheme.rowAmount,
              fit: true,
              code: shared.contains(currency),
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
        totals.income,
        AmountStyle.signed,
        first: true,
      ),
      total(l10n.transactionsExpenses, totals.expense, AmountStyle.signed),
      total(l10n.transactionsNet, net, AmountStyle.balance),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(border: Border(bottom: rule)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          large
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: figures,
                )
              : IntrinsicHeight(child: Row(children: figures)),
          if (all.length > foldedCurrencies)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: MoreCurrenciesButton(
                hidden: all.length - foldedCurrencies,
                expanded: expanded.value,
                onPressed: () => expanded.value = !expanded.value,
              ),
            ),
        ],
      ),
    );
  }
}
