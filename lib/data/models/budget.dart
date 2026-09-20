import 'package:flutter/foundation.dart';

import '../enums/budget_period.dart';

/// A budget, stored on the group or the category it caps rather than in a
/// table of its own: it has no life without the thing it belongs to.
@immutable
class Budget {
  const Budget({
    required this.targetId,
    required this.isGroup,
    required this.amount,
    required this.period,
    required this.rollover,
  });

  /// The group or the category it caps.
  final String targetId;

  /// A group's budget covers every category inside it.
  final bool isGroup;

  /// Positive micro-units per period, in the main currency.
  final int amount;
  final BudgetPeriod period;

  /// Reserved.
  final bool rollover;
}
