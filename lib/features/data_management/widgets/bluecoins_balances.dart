import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/amount_text.dart';
import '../../assets_accounts/models/assets_account_with_balance.dart';
import 'restore_preview_row.dart';

/// How many balances show before "Show all".
const _shown = 3;

/// The balance of each assets account to import, the first few until the
/// user asks for all.
class BluecoinsBalances extends HookWidget {
  const BluecoinsBalances(this.balances, {super.key});

  final List<AssetsAccountWithBalance> balances;

  @override
  Widget build(BuildContext context) {
    final all = useState(false);
    final shown = all.value ? balances : balances.take(_shown);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final b in shown)
          RestorePreviewRow.amount(
            b.account.name,
            AmountText(
              b.balance,
              currency: b.account.currency,
              amountStyle: AmountStyle.balance,
            ),
          ),
        if (!all.value && balances.length > _shown)
          TextButton(
            onPressed: () => all.value = true,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: Text(context.l10n.bluecoinsShowAll(balances.length)),
          ),
      ],
    );
  }
}
