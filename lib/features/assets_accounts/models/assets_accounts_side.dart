import 'package:flutter/foundation.dart';

import '../../../core/money/currency_converter.dart';
import '../../../data/enums/assets_account_type.dart';
import 'assets_account_type_group.dart';
import 'assets_account_with_balance.dart';

/// Assets or liabilities: their subtotal and their accounts grouped by type.
@immutable
class AssetsAccountsSide {
  const AssetsAccountsSide({
    required this.isLiability,
    required this.total,
    required this.groups,
  });

  final bool isLiability;
  final ConvertedTotal total;
  final List<AssetsAccountTypeGroup> groups;
}

/// Assets then liabilities (an empty side is left out), types in enum order,
/// [accounts] kept in their order. Subtotals leave out hidden accounts and
/// those excluded from net worth.
List<AssetsAccountsSide> groupAssetsAccounts(
  List<AssetsAccountWithBalance> accounts,
  CurrencyConverter converter,
) => [
  for (final isLiability in const [false, true])
    if (accounts.where((a) => a.account.type.isLiability == isLiability)
        case final side when side.isNotEmpty)
      AssetsAccountsSide(
        isLiability: isLiability,
        total: converter.convert(_sumByCurrency(side)),
        groups: [
          for (final type in AssetsAccountType.values)
            if (side.where((a) => a.account.type == type).toList()
                case final group when group.isNotEmpty)
              AssetsAccountTypeGroup(type, group),
        ],
      ),
];

Map<String, int> _sumByCurrency(Iterable<AssetsAccountWithBalance> accounts) {
  final sums = <String, int>{};
  for (final AssetsAccountWithBalance(:account, :balance) in accounts) {
    if (account.isHidden || account.excludeFromNetWorth) continue;
    sums[account.currency] = (sums[account.currency] ?? 0) + balance;
  }
  return sums;
}
