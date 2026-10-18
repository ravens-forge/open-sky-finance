import 'package:flutter/foundation.dart';

import '../../../core/money/currency_converter.dart';

/// What the Balance sheet compares with: net worth and every assets
/// account's balance at the end of [date].
@immutable
class BalanceSheetBaseline {
  const BalanceSheetBaseline({
    required this.date,
    required this.netWorth,
    required this.balances,
  });

  final DateTime date;

  /// In the main currency.
  final ConvertedTotal netWorth;

  /// By assets account id, in each one's own currency.
  final Map<String, int> balances;
}
