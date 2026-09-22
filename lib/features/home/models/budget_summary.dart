import 'package:flutter/foundation.dart';

import 'budget_slice.dart';

/// The budget summary pie: spending per budget this month and what is left,
/// in the main currency.
@immutable
class BudgetSummary {
  const BudgetSummary({required this.slices, required this.budgeted});

  /// In budget order.
  final List<BudgetSlice> slices;

  /// Sum of the budgets, micro-units.
  final int budgeted;

  int get spent => slices.fold(0, (sum, s) => sum + s.spent);

  /// Never negative: overspending leaves no "Remaining" slice.
  int get remaining => budgeted > spent ? budgeted - spent : 0;
}
