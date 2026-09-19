import 'package:flutter/foundation.dart';

import '../../../data/models/assets_account.dart';

@immutable
class AssetsAccountWithBalance {
  const AssetsAccountWithBalance(this.account, this.balance);

  final AssetsAccount account;

  /// Micro-units in the account's currency, as of today.
  final int balance;
}
