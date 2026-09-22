import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/info_tooltip.dart';
import 'net_worth_proportion_bar.dart';

class NetWorthHeader extends StatelessWidget {
  const NetWorthHeader({
    super.key,
    required this.assets,
    required this.liabilities,
    required this.currency,
  });

  /// In the main currency; positive.
  final int assets;

  /// In the main currency; negative or zero.
  final int liabilities;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final eyebrow = l10n.balanceSheetNetWorth.toUpperCase();
    final assetsAbs = assets.abs();
    final liabilitiesAbs = liabilities.abs();
    final total = assetsAbs + liabilitiesAbs;
    final assetsFraction = total == 0 ? 1.0 : assetsAbs / total;
    final percent = NumberFormat.decimalPercentPattern(
      locale: l10n.localeName,
      decimalDigits: 1,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow, style: text.eyebrow),
        Row(
          children: [
            Flexible(
              child: AmountText(
                assets + liabilities,
                currency: currency,
                amountStyle: AmountStyle.balance,
                style: text.hero,
              ),
            ),
            InfoTooltip(
              label: l10n.balanceSheetNetWorthInfoLabel,
              eyebrow: eyebrow,
              text: l10n.balanceSheetNetWorthInfo,
            ),
          ],
        ),
        const SizedBox(height: 4),
        NetWorthProportionBar(assetsFraction: assetsFraction),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.balanceSheetAssetsShare(percent.format(assetsFraction)),
              style: text.bodyMedium,
            ),
            Text(
              l10n.balanceSheetLiabilitiesShare(
                percent.format(1 - assetsFraction),
              ),
              style: text.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }
}
