import 'package:flutter/material.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/amount_text.dart';
import '../../assets_accounts/models/assets_account_with_balance.dart';
import 'restore_preview_row.dart';

/// How many balances show before "Show all".
const _shown = 3;

/// The balance of each assets account to import, the first few until the
/// user asks for all.
class BluecoinsBalances extends StatefulWidget {
  const BluecoinsBalances(this.balances, {super.key});

  final List<AssetsAccountWithBalance> balances;

  @override
  State<BluecoinsBalances> createState() => _BluecoinsBalancesState();
}

class _BluecoinsBalancesState extends State<BluecoinsBalances> {
  var _all = false;

  @override
  Widget build(BuildContext context) {
    final balances = widget.balances;
    final shown = _all ? balances : balances.take(_shown);
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
        if (!_all && balances.length > _shown)
          TextButton(
            onPressed: () => setState(() => _all = true),
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
