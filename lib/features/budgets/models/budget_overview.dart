import 'package:flutter/foundation.dart';

import 'budget_line.dart';

/// The Budget page for a month, in the default currency: budgets only count
/// spending in it.
@immutable
class BudgetOverview {
  const BudgetOverview({
    required this.lines,
    required this.notBudgeted,
    required this.notCounted,
    required this.currency,
  });

  /// Ordered by risk: the most spent of its budget first.
  final List<BudgetLine> lines;

  /// Spending in expense categories no budget covers.
  final int notBudgeted;

  /// Spending in other currencies, by currency: positive, never converted.
  final Map<String, int> notCounted;
  final String currency;

  int get budgeted => lines.fold(0, (sum, l) => sum + l.budget);
  int get spent => lines.fold(0, (sum, l) => sum + l.spent);

  /// Negative once over budget.
  int get remaining => budgeted - spent;
}
