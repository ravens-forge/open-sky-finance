import 'package:flutter/foundation.dart';

import '../../../core/widgets/budget_bar.dart';

/// A budgeted group or category with what was spent on it in a month, in
/// the main currency.
@immutable
class BudgetLine {
  const BudgetLine({
    required this.id,
    required this.isGroup,
    required this.name,
    required this.icon,
    required this.color,
    required this.budget,
    required this.spent,
    required this.approximate,
  });

  /// The group or the category.
  final String id;
  final bool isGroup;
  final String name;

  /// Of a category; a group has neither.
  final String? icon;
  final int? color;

  /// Micro-units, > 0.
  final int budget;

  /// Micro-units, ≥ 0.
  final int spent;

  /// Another currency was converted into [spent].
  final bool approximate;

  BudgetState get state => budgetState(spent, budget);

  /// Negative once over budget.
  int get left => budget - spent;

  /// For display and for ordering only.
  double get ratio => spent / budget;

  /// Whole per cent, never 100 unless the budget is exactly used up.
  int get percent => switch (state) {
    BudgetState.usedUp => 100,
    BudgetState.over => (ratio * 100).round().clamp(101, 1 << 31),
    _ => (ratio * 100).round().clamp(0, 99),
  };
}
