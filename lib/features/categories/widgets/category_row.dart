import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../app/theme.dart';
import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/category_avatar.dart';
import '../../../core/widgets/category_icons.dart';
import '../../../data/models/category.dart';

/// A category inside its group: drag handle, icon and name. Must sit in a
/// `ReorderableListView`.
class CategoryRow extends StatelessWidget {
  const CategoryRow({
    super.key,
    required this.category,
    required this.color,
    required this.index,
    required this.onTap,
    this.onMoveUp,
    this.onMoveDown,
  });

  final Category category;

  /// Its own colour, or its group's.
  final int color;

  /// Position in the reorderable list.
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final finance = FinanceColors.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              Semantics(
                label: l10n.categoryMove(category.name),
                customSemanticsActions: {
                  CustomSemanticsAction(label: l10n.actionMoveUp): ?onMoveUp,
                  CustomSemanticsAction(label: l10n.actionMoveDown):
                      ?onMoveDown,
                },
                child: ReorderableDragStartListener(
                  index: index,
                  child: SizedBox.square(
                    dimension: 44,
                    child: Icon(
                      Icons.drag_indicator,
                      size: 20,
                      color: finance.disabled,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              CategoryAvatar(
                icon: categoryIcon(category.icon),
                color: Color(color),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.name, style: theme.textTheme.rowTitle),
                    if (category.isHidden)
                      Text(
                        l10n.categoryHidden,
                        style: theme.textTheme.rowSubtitle,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}
