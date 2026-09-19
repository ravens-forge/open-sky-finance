import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/info_tooltip.dart';
import '../../../data/models/assets_account.dart';

/// "CURRENT BALANCE", the balance with its info tooltip, and type · currency ·
/// asset or liability.
class AssetsAccountBalanceHeader extends StatelessWidget {
  const AssetsAccountBalanceHeader({
    super.key,
    required this.account,
    required this.balance,
  });

  final AssetsAccount account;
  final int balance;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final eyebrow = l10n.fieldCurrentBalance.toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow, style: text.eyebrow),
        Row(
          children: [
            Flexible(
              child: AmountText(
                balance,
                currency: account.currency,
                amountStyle: AmountStyle.balance,
                style: text.hero,
              ),
            ),
            InfoTooltip(
              label: l10n.assetsAccountBalanceInfoLabel,
              eyebrow: eyebrow,
              text: account.type.isLiability
                  ? l10n.assetsAccountBalanceInfoLiability
                  : l10n.assetsAccountBalanceInfoAsset,
            ),
          ],
        ),
        Text(
          l10n.assetsAccountDetailSubtitle(
            account.type.label(l10n),
            account.currency,
            account.type.isLiability ? 'liability' : 'asset',
          ),
          style: text.bodySmall,
        ),
      ],
    );
  }
}
