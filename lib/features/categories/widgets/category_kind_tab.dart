import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/home_section_header.dart';
import '../../../data/enums/category_kind.dart';
import '../../../data/models/category.dart';
import '../../../data/models/category_group.dart';
import '../models/category_group_node.dart';
import '../providers/categories_controller.dart';
import 'category_add_row.dart';
import 'category_group_tile.dart';
import 'category_row.dart';

/// The groups of [kind] with their categories, expandable and reorderable.
class CategoryKindTab extends ConsumerStatefulWidget {
  const CategoryKindTab({
    super.key,
    required this.kind,
    required this.groups,
    required this.categories,
  });

  final CategoryKind kind;

  /// Every group and every category, in sort order: reordering rewrites the
  /// whole order.
  final List<CategoryGroup> groups;
  final List<Category> categories;

  @override
  ConsumerState<CategoryKindTab> createState() => _CategoryKindTabState();
}

class _CategoryKindTabState extends ConsumerState<CategoryKindTab> {
  /// Groups start expanded, so a group that is still empty says so.
  final _collapsed = <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final nodes = groupCategories(
      widget.groups,
      widget.categories,
      widget.kind,
    );
    if (nodes.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: EmptyState(
            title: l10n.categoriesEmpty,
            actions: [
              FilledButton(
                onPressed: () =>
                    context.push(Routes.newCategoryGroup(widget.kind)),
                child: Text(l10n.editorNewCategoryGroup),
              ),
            ],
          ),
        ),
      );
    }

    final controller = ref.read(categoriesControllerProvider.notifier);
    final allGroupIds = [for (final g in widget.groups) g.id];
    final allIds = [for (final c in widget.categories) c.id];
    final groupIds = [for (final node in nodes) node.group.id];

    // Groups and categories share one list; a row only moves within its own
    // ids, kept per row index together with its position in them.
    final children = <Widget>[];
    final owner = <List<String>?>[];
    final position = <int>[];
    for (final (g, node) in nodes.indexed) {
      final group = node.group;
      final expanded = !_collapsed.contains(group.id);
      void moveGroup(int to) {
        final from = allGroupIds.indexOf(group.id);
        final target = allGroupIds.indexOf(groupIds[to]);
        if (from != target) controller.moveGroup(allGroupIds, from, target);
      }

      children.add(
        CategoryGroupTile(
          key: ValueKey(group.id),
          node: node,
          index: children.length,
          expanded: expanded,
          onToggle: () => setState(
            () => expanded
                ? _collapsed.add(group.id)
                : _collapsed.remove(group.id),
          ),
          onTap: () => context.push(Routes.categoryGroup(group.id)),
          onMoveUp: g > 0 ? () => moveGroup(g - 1) : null,
          onMoveDown: g < nodes.length - 1 ? () => moveGroup(g + 1) : null,
        ),
      );
      owner.add(groupIds);
      position.add(g);
      if (!expanded) continue;

      final ids = [for (final category in node.categories) category.id];
      void move(int from, int to) {
        if (from != to) controller.move(allIds, ids, from, to);
      }

      for (final (i, category) in node.categories.indexed) {
        children.add(
          CategoryRow(
            key: ValueKey(category.id),
            category: category,
            index: children.length,
            onTap: () => context.push(Routes.category(category.id)),
            onMoveUp: i > 0 ? () => move(i, i - 1) : null,
            onMoveDown: i < ids.length - 1 ? () => move(i, i + 1) : null,
          ),
        );
        owner.add(ids);
        position.add(i);
      }
      children.add(
        CategoryAddRow(
          key: ValueKey('add:${group.id}'),
          group: group,
          isEmpty: node.categories.isEmpty,
        ),
      );
      owner.add(null);
      position.add(0);
    }

    return ReorderableListView(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      proxyDecorator: homeSectionProxyDecorator,
      footer: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: OutlinedButton.icon(
          onPressed: () => context.push(Routes.newCategoryGroup(widget.kind)),
          icon: const Icon(Icons.add, size: 18),
          label: Text(l10n.categoriesNewGroup),
        ),
      ),
      onReorderItem: (from, to) {
        if (to >= owner.length) return;
        final ids = owner[from];
        if (ids == null || !identical(owner[to], ids)) return;
        if (identical(ids, groupIds)) {
          final start = allGroupIds.indexOf(ids[position[from]]);
          final target = allGroupIds.indexOf(ids[position[to]]);
          if (start != target) {
            controller.moveGroup(allGroupIds, start, target);
          }
          return;
        }
        if (position[from] != position[to]) {
          controller.move(allIds, ids, position[from], position[to]);
        }
      },
      children: children,
    );
  }
}
