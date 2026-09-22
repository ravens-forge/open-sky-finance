import 'package:flutter/foundation.dart';

import '../../../core/money/currency_converter.dart';
import '../../../data/enums/assets_account_type.dart';
import '../../assets_accounts/models/assets_account_with_balance.dart';
import 'balance_sheet_type_group.dart';

/// Assets or liabilities: their subtotal and their accounts grouped by type.
@immutable
class BalanceSheetSide {
  const BalanceSheetSide({
    required this.isLiability,
    required this.total,
    required this.groups,
  });

  final bool isLiability;
  final ConvertedTotal total;
  final List<BalanceSheetTypeGroup> groups;
}

/// Assets then liabilities (an empty side is left out), types in enum order,
/// [accounts] kept in their order. [accounts] must already exclude hidden
/// ones; subtotals (side and type) also leave out those excluded from net
/// worth, which stay in the list.
List<BalanceSheetSide> groupBalanceSheet(
  List<AssetsAccountWithBalance> accounts,
  CurrencyConverter converter,
) => [
  for (final isLiability in const [false, true])
    if (accounts.where((a) => a.account.type.isLiability == isLiability)
        case final side when side.isNotEmpty)
      BalanceSheetSide(
        isLiability: isLiability,
        total: converter.convert(_sumByCurrency(side)),
        groups: [
          for (final type in AssetsAccountType.values)
            if (side.where((a) => a.account.type == type).toList()
                case final group when group.isNotEmpty)
              BalanceSheetTypeGroup(
                type: type,
                total: converter.convert(_sumByCurrency(group)),
                accounts: group,
              ),
        ],
      ),
];

Map<String, int> _sumByCurrency(Iterable<AssetsAccountWithBalance> accounts) {
  final sums = <String, int>{};
  for (final AssetsAccountWithBalance(:account, :balance) in accounts) {
    if (account.excludeFromNetWorth) continue;
    sums[account.currency] = (sums[account.currency] ?? 0) + balance;
  }
  return sums;
}
