import 'package:flutter/foundation.dart';

import '../../../core/dates/year_month.dart';

/// Income and expenses of one month in the report currency, for the Home
/// charts.
@immutable
class CashFlowMonth {
  const CashFlowMonth(
    this.month, {
    required this.income,
    required this.expense,
  });

  final YearMonth month;

  /// Micro-units, ≥ 0 unless refunds outweigh income.
  final int income;

  /// Micro-units, negative; refunds make it smaller.
  final int expense;

  int get net => income + expense;
}
