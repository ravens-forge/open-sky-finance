import 'package:flutter/foundation.dart';

import 'budget.dart';

/// A budget and what was spent on it in a month.
@immutable
class BudgetProgress {
  const BudgetProgress({required this.budget, required this.spent});

  final Budget budget;

  /// Positive micro-units by currency; refunds reduce it.
  final Map<String, int> spent;
}
