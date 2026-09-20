import 'package:flutter/foundation.dart' hide Category;

/// A category inside a group, and the only thing a transaction, a reminder or
/// a budget points at. Its type is its group's, so the two can never
/// disagree.
@immutable
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.groupId,
    required this.icon,
    required this.color,
    required this.isHidden,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String groupId;

  /// Material icon key in snake_case.
  final String icon;

  /// ARGB.
  final int color;
  final bool isHidden;
  final int sortOrder;
}
