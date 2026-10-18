import 'package:flutter/material.dart';

import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/money/format_money.dart';
import '../../../core/widgets/amount_text.dart';

/// How much a balance moved: an arrow and a signed amount, `income` when it
/// raised net worth and `expense` when it lowered it (a growing debt too).
class BalanceChange extends StatelessWidget {
  const BalanceChange(
    this.micros, {
    super.key,
    required this.currency,
    this.suffix,
    this.style,
  });

  final int micros;
  final String currency;

  /// Shown after the amount, in the same colour, e.g. " (+3.7%)".
  final String? suffix;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = FinanceColors.of(context);
    final amount = formatMoney(
      micros.abs(),
      currency: currency,
      locale: l10n.localeName,
    );
    final spoken = spokenMoney(micros.abs(), currency, l10n);
    final (icon, sign, color, label) = switch (micros) {
      > 0 => (
        Icons.arrow_drop_up,
        '+',
        colors.income,
        l10n.balanceSheetChangeUp(spoken),
      ),
      < 0 => (
        Icons.arrow_drop_down,
        '−',
        colors.expense,
        l10n.balanceSheetChangeDown(spoken),
      ),
      _ => (Icons.remove, '', colors.muted, l10n.balanceSheetChangeNone),
    };
    final text = (style ?? DefaultTextStyle.of(context).style).copyWith(
      color: color,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Semantics(
      label: '$label${suffix ?? ''}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: (text.fontSize ?? 14) * 1.3, color: color),
          Text('$sign$amount${suffix ?? ''}', style: text),
        ],
      ),
    );
  }
}
