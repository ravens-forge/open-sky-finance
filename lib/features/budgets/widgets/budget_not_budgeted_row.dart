import 'package:flutter/material.dart';

import '../../../core/l10n.dart';
import '../../../core/money/currency_converter.dart';
import '../../../core/money/format_money.dart';
import '../../../core/widgets/info_tooltip.dart';
import '../../../core/widgets/trailing_amount.dart';

class BudgetNotBudgetedRow extends StatelessWidget {
  const BudgetNotBudgetedRow({
    super.key,
    required this.total,
    required this.currency,
    required this.onAdd,
  });

  final ConvertedTotal total;
  final String currency;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = l10n.localeName;
    final amount = formatMoney(
      total.amount,
      currency: currency,
      locale: locale,
    );
    final shown = total.approximate ? l10n.amountApproximate(amount) : amount;
    final text = l10n.budgetNotBudgeted(shown);
    final at = text.indexOf(shown);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.colorScheme.onSurface)),
      ),
      child: TrailingAmount(
        text: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      children: [
                        TextSpan(text: text.substring(0, at)),
                        TextSpan(
                          text: shown,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        TextSpan(text: text.substring(at + shown.length)),
                      ],
                    ),
                  ),
                ),
                InfoTooltip(
                  label: l10n.budgetNotBudgetedInfoLabel,
                  text: l10n.budgetNotBudgetedInfo,
                ),
              ],
            ),
            if (total.notIncluded.isNotEmpty)
              Text(
                l10n.assetsAccountsNotIncluded(
                  [
                    for (final MapEntry(key: currency, value: micros)
                        in total.notIncluded.entries)
                      formatMoney(micros, currency: currency, locale: locale),
                  ].join(', '),
                ),
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
        amount: OutlinedButton(
          onPressed: onAdd,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            textStyle: theme.textTheme.labelLarge!.copyWith(fontSize: 13),
          ),
          child: Text(l10n.actionAdd),
        ),
      ),
    );
  }
}
