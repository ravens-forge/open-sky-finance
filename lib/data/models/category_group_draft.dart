import 'package:flutter/foundation.dart';

import '../enums/category_kind.dart';

/// What the group editor saves; [id] `null` creates one.
@immutable
class CategoryGroupDraft {
  const CategoryGroupDraft({
    this.id,
    required this.name,
    required this.kind,
    this.isHidden = false,
  });

  final String? id;
  final String name;
  final CategoryKind kind;
  final bool isHidden;
}
