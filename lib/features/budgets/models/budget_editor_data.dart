import 'package:flutter/foundation.dart';

import '../../../core/dates/year_month.dart';
import '../../categories/models/category_group_node.dart';

/// What Edit budgets starts from.
@immutable
class BudgetEditorData {
  const BudgetEditorData({
    required this.groups,
    required this.budgets,
    required this.spent,
    required this.month,
    required this.currency,
  });

  /// Expense groups with their categories, hidden ones included.
  final List<CategoryGroupNode> groups;

  /// Micro-units by group or category id.
  final Map<String, int> budgets;

  /// Spent in [month] by category id: micro-units of [currency], positive.
  final Map<String, int> spent;
  final YearMonth month;

  /// The main currency.
  final String currency;
}
