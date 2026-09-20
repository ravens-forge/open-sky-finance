import 'package:flutter/foundation.dart';

/// What a category is used by, and what deleting it would touch.
@immutable
class CategoryUsage {
  const CategoryUsage({
    required this.transactions,
    required this.reminders,
    required this.subcategories,
    required this.hasBudget,
  });

  /// Nothing uses it yet: what a category being created has.
  static const none = CategoryUsage(
    transactions: 0,
    reminders: 0,
    subcategories: 0,
    hasBudget: false,
  );

  /// Transactions in this category, trashed ones included. Transactions in
  /// its subcategories are not counted.
  final int transactions;
  final int reminders;

  /// Categories inside it; only a group has them, and it cannot be deleted
  /// while it does.
  final int subcategories;

  /// Removed with the category.
  final bool hasBudget;

  /// Nothing has to be moved when it is deleted.
  bool get isUnused => transactions == 0 && reminders == 0;
}
