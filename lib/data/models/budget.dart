import 'package:flutter/foundation.dart';

import '../enums/budget_period.dart';

@immutable
class Budget {
  const Budget({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.period,
    required this.rollover,
  });

  final String id;

  /// An expense group (includes its subcategories) or subcategory.
  final String categoryId;

  /// Positive micro-units per period, in the main currency.
  final int amount;
  final BudgetPeriod period;

  /// Reserved.
  final bool rollover;
}
