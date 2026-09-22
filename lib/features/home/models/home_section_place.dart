import 'package:flutter/foundation.dart';

/// Where a section sits among the visible ones on Home, and its non-drag
/// "Move up" / "Move down" actions (`null` at either end).
@immutable
class HomeSectionPlace {
  const HomeSectionPlace(this.index, {this.onMoveUp, this.onMoveDown});

  final int index;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
}
