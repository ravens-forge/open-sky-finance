import 'package:flutter/foundation.dart';

import '../../../data/enums/assets_account_type.dart';
import 'assets_account_with_balance.dart';

/// The assets accounts of one type, in their sort order.
@immutable
class AssetsAccountTypeGroup {
  const AssetsAccountTypeGroup(this.type, this.accounts);

  final AssetsAccountType type;
  final List<AssetsAccountWithBalance> accounts;
}
