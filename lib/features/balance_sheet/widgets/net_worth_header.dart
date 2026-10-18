import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/info_tooltip.dart';
import '../models/balance_sheet_baseline.dart';
import 'balance_change.dart';
import 'net_worth_proportion_bar.dart';

class NetWorthHeader extends StatelessWidget {
  const NetWorthHeader({
    super.key,
    required this.assets,
    required this.liabilities,
    required this.currency,
    this.baseline,
  });

  /// In the main currency; positive.
  final int assets;

  /// In the main currency; negative or zero.
  final int liabilities;
  final String currency;

  /// Net worth to compare with, in the main currency.
  final BalanceSheetBaseline? baseline;

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
                fit: true,
              ),
            ),
            InfoTooltip(
              label: l10n.balanceSheetNetWorthInfoLabel,
              eyebrow: eyebrow,
              text: l10n.balanceSheetNetWorthInfo,
            ),
          ],
        ),
        if (baseline case final baseline?)
          _Change(
            change: assets + liabilities - baseline.netWorth.amount,
            before: baseline.netWorth.amount,
            date: DateFormat.yMMMd(l10n.localeName).format(baseline.date),
            currency: currency,
          ),
        const SizedBox(height: 4),
        NetWorthProportionBar(assetsFraction: assetsFraction),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
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
        ),
      ],
    );
  }
}

/// "▲ +€1,730.15 (+3.7%) since Aug 17, 2026"; no percentage from zero.
class _Change extends StatelessWidget {
  const _Change({
    required this.change,
    required this.before,
    required this.date,
    required this.currency,
  });

  final int change;
  final int before;
  final String date;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = Theme.of(context).textTheme.bodyMedium;
    final percent = NumberFormat.decimalPercentPattern(
      locale: l10n.localeName,
      decimalDigits: 1,
    );
    final share = before == 0 || change == 0
        ? null
        : '${change > 0 ? '+' : '−'}${percent.format((change / before).abs())}';
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        BalanceChange(
          change,
          currency: currency,
          suffix: share == null ? null : ' ($share)',
          style: style,
        ),
        Text(l10n.balanceSheetSince(date), style: style),
      ],
    );
  }
}
