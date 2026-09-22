import 'package:flutter/foundation.dart';

/// What was spent this month on one budgeted category or group, in the main
/// currency.
@immutable
class BudgetSlice {
  const BudgetSlice({required this.name, required this.spent});

  final String name;

  /// Micro-units, ≥ 0.
  final int spent;
}
