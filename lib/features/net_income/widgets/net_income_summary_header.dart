import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/info_tooltip.dart';
import '../models/net_income_summary.dart';

class NetIncomeSummaryHeader extends StatelessWidget {
  const NetIncomeSummaryHeader({
    super.key,
    required this.summary,
    required this.currency,
  });

  final NetIncomeSummary summary;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final percent = NumberFormat.decimalPercentPattern(
      locale: l10n.localeName,
      decimalDigits: 1,
    ).format(summary.savingsRate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _row(l10n.netIncomeIncome, summary.income.amount, text.bodyLarge!),
        _row(l10n.netIncomeExpenses, summary.expense.amount, text.bodyLarge!),
        Container(
          padding: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: scheme.onSurface, width: 3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                l10n.netIncomeNet,
                style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w700),
              ),
              InfoTooltip(
                label: l10n.netIncomeInfoLabel,
                text: l10n.netIncomeInfo,
              ),
              const Spacer(),
              AmountText(
                summary.net.amount,
                currency: currency,
                amountStyle: AmountStyle.signed,
                approximate: summary.net.approximate,
                style: text.hero.copyWith(fontSize: 34),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              l10n.netIncomeSavingsRateLabel(percent),
              style: text.bodySmall,
            ),
            InfoTooltip(
              label: l10n.netIncomeSavingsRateInfoLabel,
              text: l10n.netIncomeSavingsRateInfo,
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(String label, int amount, TextStyle style) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        AmountText(
          amount,
          currency: currency,
          amountStyle: AmountStyle.signed,
          style: style.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
