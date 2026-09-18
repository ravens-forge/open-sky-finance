import 'package:flutter/foundation.dart';

import '../enums/category_kind.dart';

/// What the category and group editors save. [parentId] `null` is a group;
/// [id] `null` creates one.
@immutable
class CategoryDraft {
  const CategoryDraft({
    this.id,
    required this.name,
    required this.kind,
    this.parentId,
    required this.icon,
    this.color,
    this.isHidden = false,
  });

  final String? id;
  final String name;
  final CategoryKind kind;
  final String? parentId;
  final String icon;

  /// ARGB; required for groups.
  final int? color;
  final bool isHidden;
}
