import 'package:flutter/foundation.dart';

import '../../../data/models/assets_account.dart';

/// What the editor starts from.
@immutable
class AssetsAccountEditorData {
  const AssetsAccountEditorData({
    required this.account,
    required this.currency,
    required this.openingBalance,
    required this.openingBalanceDate,
    required this.transactionCount,
  });

  /// `null` when creating.
  final AssetsAccount? account;

  /// The account's, or the main currency for a new one.
  final String currency;
  final int openingBalance;
  final DateTime openingBalanceDate;

  /// Besides the opening balance; above zero locks the currency.
  final int transactionCount;
}
