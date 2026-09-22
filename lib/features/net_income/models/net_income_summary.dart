import 'package:flutter/foundation.dart';

import '../../../core/money/currency_converter.dart';

@immutable
class NetIncomeSummary {
  const NetIncomeSummary({
    required this.income,
    required this.expense,
    required this.net,
    required this.savingsRate,
  });

  final ConvertedTotal income;

  /// Negative.
  final ConvertedTotal expense;
  final ConvertedTotal net;

  /// Net income as a share of income; 0 with no income.
  final double savingsRate;
}
