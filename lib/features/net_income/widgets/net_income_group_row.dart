import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/amount_text.dart';
import '../models/net_income_category_group.dart';

class NetIncomeGroupRow extends StatelessWidget {
  const NetIncomeGroupRow({
    super.key,
    required this.group,
    required this.currency,
  });

  final NetIncomeCategoryGroup group;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final percent = NumberFormat.decimalPercentPattern(
      locale: l10n.localeName,
      decimalDigits: 1,
    ).format(group.share);

    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            group.name ?? l10n.categoryNone,
            style: theme.textTheme.bodyLarge!.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(percent, style: theme.textTheme.bodySmall),
          const Spacer(),
          AmountText(
            group.total.amount,
            currency: currency,
            amountStyle: AmountStyle.signed,
            approximate: group.total.approximate,
            style: theme.textTheme.bodyLarge!.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
