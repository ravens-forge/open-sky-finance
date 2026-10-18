import 'package:flutter/foundation.dart';

@immutable
class NetIncomeSummary {
  const NetIncomeSummary({
    required this.income,
    required this.expense,
    required this.net,
    required this.savingsRate,
  });

  /// Micro-units of the report currency.
  final int income;

  /// Negative.
  final int expense;
  final int net;

  /// Net income as a share of income; 0 with no income.
  final double savingsRate;
}
