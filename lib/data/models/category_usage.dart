import 'package:flutter/foundation.dart';

/// What a category or a group is used by, and what deleting it would touch.
@immutable
class CategoryUsage {
  const CategoryUsage({
    required this.transactions,
    required this.reminders,
    required this.categories,
    required this.hasBudget,
  });

  /// Nothing uses it yet: what a category being created has.
  static const none = CategoryUsage(
    transactions: 0,
    reminders: 0,
    categories: 0,
    hasBudget: false,
  );

  /// Trashed ones included. For a group, those of all its categories.
  final int transactions;
  final int reminders;

  /// Categories inside it; only a group has them, and it cannot be deleted
  /// while it does.
  final int categories;

  /// Goes with it when it is deleted.
  final bool hasBudget;

  /// Nothing has to be moved when it is deleted.
  bool get isUnused => transactions == 0 && reminders == 0;
}
