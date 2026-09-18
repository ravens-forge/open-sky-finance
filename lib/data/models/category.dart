import 'package:flutter/foundation.dart';

import '../enums/category_kind.dart';

@immutable
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.kind,
    required this.parentId,
    required this.icon,
    required this.color,
    required this.isHidden,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final CategoryKind kind;
  final String? parentId;

  /// Material icon key in snake_case.
  final String icon;

  /// ARGB. Always set on groups; `null` on a subcategory means its group's colour.
  final int? color;
  final bool isHidden;
  final int sortOrder;

  bool get isGroup => parentId == null;
}
