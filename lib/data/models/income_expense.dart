/// Income and expenses of a period, by currency. Transfers and opening balances
/// are neither.
class IncomeExpense {
  IncomeExpense([Map<String, int>? income, Map<String, int>? expense])
    : income = income ?? {},
      expense = expense ?? {};

  final Map<String, int> income;

  /// Negative; refunds make it smaller.
  final Map<String, int> expense;

  /// Net income: income + expense.
  Map<String, int> get net => {
    for (final c in {...income.keys, ...expense.keys})
      c: (income[c] ?? 0) + (expense[c] ?? 0),
  };
}
