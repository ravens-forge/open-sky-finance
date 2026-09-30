import 'package:flutter/foundation.dart';

import '../../../core/money/currency_converter.dart';
import 'budget_line.dart';

/// The Budget page for a month, in the main currency.
@immutable
class BudgetOverview {
  const BudgetOverview({
    required this.lines,
    required this.notBudgeted,
    required this.notIncluded,
    required this.currency,
  });

  /// Ordered by risk: the most spent of its budget first.
  final List<BudgetLine> lines;

  /// Spending in expense categories no budget covers.
  final ConvertedTotal notBudgeted;

  /// Spending on budgets left out because its currency has no rate yet.
  final Map<String, int> notIncluded;
  final String currency;

  int get budgeted => lines.fold(0, (sum, l) => sum + l.budget);
  int get spent => lines.fold(0, (sum, l) => sum + l.spent);

  /// Negative once over budget.
  int get remaining => budgeted - spent;
  bool get approximate => lines.any((l) => l.approximate);
}
