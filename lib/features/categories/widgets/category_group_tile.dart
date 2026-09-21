import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../app/theme.dart';
import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/category_avatar.dart';
import '../models/category_group_node.dart';

/// A category group: drag handle, the arrow of its type in its type's
/// colour, name, how many categories it holds and the expand toggle. Must sit
/// in a `ReorderableListView`.
class CategoryGroupTile extends StatelessWidget {
  const CategoryGroupTile({
    super.key,
    required this.node,
    required this.index,
    required this.expanded,
    required this.onToggle,
    required this.onTap,
    this.onMoveUp,
    this.onMoveDown,
  });

  final CategoryGroupNode node;

  /// Position in the reorderable list.
  final int index;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final finance = FinanceColors.of(context);
    final group = node.group;
    final color = group.kind.color(context);
    return Material(
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              Semantics(
                label: l10n.categoryMove(group.name),
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
              CategoryAvatar(
                icon: group.kind.icon,
                color: color,
                background: color.withValues(alpha: 0.14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: theme.textTheme.rowTitle.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      [
                        l10n.categoriesCount(node.categories.length),
                        if (group.isHidden) l10n.categoryHidden,
                      ].join(' · '),
                      style: theme.textTheme.rowSubtitle,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: expanded
                    ? l10n.categoriesCollapse(group.name)
                    : l10n.categoriesExpand(group.name),
                onPressed: onToggle,
                icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
