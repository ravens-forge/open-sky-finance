import 'package:flutter/material.dart';

import '../finance_colors.dart';
import '../l10n.dart';
import '../money/format_money.dart';

enum AmountStyle {
  /// Income and expenses: `+` in `income` when positive, `−` in `expense` when
  /// negative (a refund is a positive expense, so it shows as income).
  signed,

  /// `⇄` and the amount in `transfer`.
  transfer,

  /// Balances and totals: plain when positive, `−` in `expense` when negative.
  balance,
}

/// [micros] read aloud with the currency name.
/// Unknown currencies fall back to the ISO code.
String spokenMoney(int micros, String currency, AppLocalizations l10n) =>
    l10n.moneySpoken(
      formatMoney(
        micros,
        currency: currency,
        locale: l10n.localeName,
        symbol: false,
      ),
      currency,
    );

/// A money amount with its sign or symbol, semantic colour and a spoken label
/// ("expense, 12.50 euros").
class AmountText extends StatelessWidget {
  const AmountText(
    this.micros, {
    super.key,
    required this.currency,
    this.amountStyle = AmountStyle.signed,
    this.style,
  });

  final int micros;
  final String currency;
  final AmountStyle amountStyle;
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

    final (String text, Color? color, String label) = switch (amountStyle) {
      AmountStyle.transfer => (
        '⇄ $amount',
        colors.transfer,
        l10n.amountTransferSemantic(spoken),
      ),
      _ when micros < 0 => (
        '−$amount',
        colors.expense,
        amountStyle == AmountStyle.signed
            ? l10n.amountExpenseSemantic(spoken)
            : l10n.amountNegativeSemantic(spoken),
      ),
      AmountStyle.signed when micros > 0 => (
        '+$amount',
        colors.income,
        l10n.amountIncomeSemantic(spoken),
      ),
      _ => (amount, null, spoken),
    };

    return Text(
      text,
      semanticsLabel: label,
      style: (style ?? const TextStyle()).copyWith(
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
