import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/l10n.dart';
import '../../../core/money/format_money.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/leader_row.dart';
import '../../assets_accounts/models/assets_account_with_balance.dart';
import '../../assets_accounts/models/credit_usage.dart';
import '../../assets_accounts/widgets/credit_usage_bar.dart';

/// One assets account: name, dotted leader, balance in its own currency; a
/// credit card with a limit adds its usage below, an account excluded from
/// net worth is marked as such.
class BalanceSheetAccountRow extends StatelessWidget {
  const BalanceSheetAccountRow({
    super.key,
    required this.item,
    required this.onTap,
  });

  final AssetsAccountWithBalance item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final AssetsAccountWithBalance(:account, :balance) = item;
    final usage = CreditUsage.of(account, balance);
    String money(int micros) => formatMoney(
      micros,
      currency: account.currency,
      locale: l10n.localeName,
    );

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 12, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LeaderRow(
            name: account.name,
            amount: AmountText(
              balance,
              currency: account.currency,
              amountStyle: AmountStyle.balance,
              style: theme.textTheme.rowAmount,
            ),
            onTap: onTap,
          ),
          if (account.excludeFromNetWorth)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                l10n.assetsAccountExcluded,
                style: theme.textTheme.bodySmall,
              ),
            ),
          if (usage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 4,
                children: [
                  CreditUsageBar(usage),
                  Text(
                    l10n.balanceSheetCreditLimitUsed(
                      NumberFormat.decimalPercentPattern(
                        locale: l10n.localeName,
                        decimalDigits: 1,
                      ).format(usage.used / usage.limit),
                      money(usage.limit),
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
