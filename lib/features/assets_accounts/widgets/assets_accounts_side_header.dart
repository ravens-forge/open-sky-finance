import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/l10n.dart';
import '../../../core/money/currency_converter.dart';
import '../../../core/money/format_money.dart';
import '../../../core/widgets/amount_text.dart';

/// "Assets" or "Liabilities" with the subtotal in the main currency, and the
/// balances left out of it for lack of an exchange rate.
class AssetsAccountsSideHeader extends StatelessWidget {
  const AssetsAccountsSideHeader({
    super.key,
    required this.title,
    required this.total,
    required this.mainCurrency,
  });

  final String title;
  final ConvertedTotal total;
  final String mainCurrency;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.onSurface),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: theme.textTheme.sectionTitle),
                  ),
                ),
                AmountText(
                  total.amount,
                  currency: mainCurrency,
                  amountStyle: AmountStyle.balance,
                  approximate: total.approximate,
                  style: theme.textTheme.rowAmount.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (total.notIncluded.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l10n.assetsAccountsNotIncluded(
                  [
                    for (final MapEntry(key: currency, value: micros)
                        in total.notIncluded.entries)
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
      ),
    );
  }
}
