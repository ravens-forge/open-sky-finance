import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/main_currency.dart';
import '../../../app/now.dart';
import '../../../app/theme.dart';
import '../../../core/l10n.dart';
import '../../../core/money/currency_converter.dart';
import '../../../core/widgets/amount_text.dart';
import '../providers/home_providers.dart';

/// Net worth today and this month's net income, side by side. It has no
/// title, so it moves only from Arrange Home.
class SummarySection extends ConsumerWidget {
  const SummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final line = BorderSide(color: theme.colorScheme.outlineVariant);
    final currency = ref.watch(mainCurrencyProvider).value;
    final netWorth = ref.watch(homeNetWorthTodayProvider).value;
    final netIncome = ref.watch(homeNetIncomeThisMonthProvider).value;
    final month = DateFormat.MMM(l10n.localeName)
        .format(ref.watch(currentMonthProvider).start);

    Widget figure(
      String label,
      ConvertedTotal? total,
      AmountStyle style,
      EdgeInsetsDirectional padding,
    ) => Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          if (total != null && currency != null)
            AmountText(
              total.amount,
              currency: currency,
              amountStyle: style,
              approximate: total.approximate,
              style: theme.textTheme.summaryFigure,
            ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(border: Border(bottom: line)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: figure(
                  l10n.homeSectionNetWorth,
                  netWorth,
                  AmountStyle.balance,
                  const EdgeInsetsDirectional.only(end: 12),
                ),
              ),
              VerticalDivider(width: 1, color: line.color),
              Expanded(
                child: figure(
                  l10n.homeNetIncomeMonth(month),
                  netIncome,
                  AmountStyle.signed,
                  const EdgeInsetsDirectional.only(start: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
