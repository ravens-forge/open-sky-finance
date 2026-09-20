import 'package:flutter/foundation.dart';

/// What the category editor saves; [id] `null` creates one. The type is not
/// here: it comes from the group.
@immutable
class CategoryDraft {
  const CategoryDraft({
    this.id,
    required this.name,
    required this.groupId,
    required this.icon,
    required this.color,
    this.isHidden = false,
  });

  final String? id;
  final String name;
  final String groupId;
  final String icon;

  /// ARGB; every category has one of its own.
  final int color;
  final bool isHidden;
}
