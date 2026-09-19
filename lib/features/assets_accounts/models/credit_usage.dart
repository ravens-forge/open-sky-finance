import 'package:flutter/foundation.dart';

import '../../../data/enums/assets_account_type.dart';
import '../../../data/models/assets_account.dart';

/// How much of a credit card's limit is used. Micro-units.
@immutable
class CreditUsage {
  const CreditUsage({required this.used, required this.limit});

  /// Credit cards with a limit; `null` for anything else.
  static CreditUsage? of(AssetsAccount account, int balance) =>
      account.type == AssetsAccountType.creditCard &&
          (account.creditLimit ?? 0) > 0
      ? CreditUsage(
          used: balance < 0 ? -balance : 0,
          limit: account.creditLimit!,
        )
      : null;

  final int used;
  final int limit;

  /// Negative when over the limit.
  int get available => limit - used;

  /// 0–1, for the bar.
  double get fraction => (used / limit).clamp(0, 1);
}
