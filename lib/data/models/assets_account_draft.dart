import 'package:flutter/foundation.dart';

import '../enums/assets_account_type.dart';

/// What the assets account editor saves. [id] `null` creates an assets account.
@immutable
class AssetsAccountDraft {
  const AssetsAccountDraft({
    this.id,
    required this.name,
    required this.type,
    required this.currency,
    this.isHidden = false,
    this.isFavorite = false,
    this.excludeFromNetWorth = false,
    this.creditLimit,
    this.notes = '',
    this.openingBalance = 0,
    required this.openingBalanceDate,
  });

  final String? id;
  final String name;
  final AssetsAccountType type;
  final String currency;
  final bool isHidden;
  final bool isFavorite;
  final bool excludeFromNetWorth;

  /// Micro-units, credit cards only.
  final int? creditLimit;
  final String notes;

  /// Signed micro-units; 0 = no opening balance transaction.
  final int openingBalance;
  final DateTime openingBalanceDate;
}
