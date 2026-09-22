import 'package:flutter/material.dart';

import '../../../core/widgets/amount_text.dart';

/// A type's name and subtotal ("Bank €30,440.22") above its accounts.
class BalanceSheetTypeHeader extends StatelessWidget {
  const BalanceSheetTypeHeader({
    super.key,
    required this.label,
    required this.amount,
    required this.mainCurrency,
    required this.approximate,
  });

  final String label;
  final int amount;
  final String mainCurrency;
  final bool approximate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall!.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 13,
      color: theme.colorScheme.onSurface,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          AmountText(
            amount,
            currency: mainCurrency,
            amountStyle: AmountStyle.balance,
            approximate: approximate,
            style: style,
          ),
        ],
      ),
    );
  }
}
