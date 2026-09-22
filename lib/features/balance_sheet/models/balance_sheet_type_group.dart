import 'package:flutter/foundation.dart';

import '../../../core/money/currency_converter.dart';
import '../../../data/enums/assets_account_type.dart';
import '../../assets_accounts/models/assets_account_with_balance.dart';

@immutable
class BalanceSheetTypeGroup {
  const BalanceSheetTypeGroup({
    required this.type,
    required this.total,
    required this.accounts,
  });

  final AssetsAccountType type;
  final ConvertedTotal total;
  final List<AssetsAccountWithBalance> accounts;
}
