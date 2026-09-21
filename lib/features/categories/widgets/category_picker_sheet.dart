import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/text/sort_key.dart';
import '../../../core/widgets/category_avatar.dart';
import '../../../core/widgets/category_icons.dart';
import '../../../core/widgets/picker_row.dart';
import '../../../core/widgets/picker_sheet.dart';
import '../../../data/enums/category_kind.dart';
import '../../../data/models/category.dart';
import '../../../data/models/category_group.dart';
import '../models/category_group_node.dart';
import '../providers/categories_providers.dart';

/// Picks a category of [kind]. Groups are headings in their type's colour,
/// not choices: a transaction always points at a category. Hidden categories,
/// and the categories of a hidden group, are left out. Returns the chosen id,
/// `null` when dismissed.
Future<String?> showCategoryPickerSheet(
  BuildContext context, {
  required CategoryKind kind,
  String? selectedId,
  String? excludeId,
  bool showActions = true,
}) => showPickerSheet<String>(
  context,
  (context) => CategoryPickerSheet(
    kind: kind,
    selectedId: selectedId,
    excludeId: excludeId,
    showActions: showActions,
  ),
);

class CategoryPickerSheet extends ConsumerStatefulWidget {
  const CategoryPickerSheet({
    super.key,
    required this.kind,
    this.selectedId,
    this.excludeId,
    this.showActions = true,
  });

  final CategoryKind kind;
  final String? selectedId;

  /// Left out of the list, e.g. the category being deleted.
  final String? excludeId;

  /// "New category" and "Manage"; off where leaving the sheet would drop
  /// what the caller is in the middle of.
  final bool showActions;

  @override
  ConsumerState<CategoryPickerSheet> createState() =>
      _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends ConsumerState<CategoryPickerSheet> {
  var _query = '';

  void _leave(BuildContext context, String location) {
    final router = GoRouter.of(context);
    Navigator.pop(context);
    router.push(location);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final nodes = groupCategories(
      ref.watch(categoryGroupsProvider).value ?? const <CategoryGroup>[],
      ref.watch(categoriesProvider).value ?? const <Category>[],
      widget.kind,
      includeHidden: false,
    );
    final query = sortKey(_query.trim());
    bool matches(String name) => sortKey(name).contains(query);

    final rows = <Widget>[];
    for (final node in nodes) {
      final wholeGroup = query.isEmpty || matches(node.group.name);
      final categories = [
        for (final category in node.categories)
          if (category.id != widget.excludeId &&
              (wholeGroup || matches(category.name)))
            category,
      ];
      if (categories.isEmpty) continue;
      rows.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(
            spacing: 8,
            children: [
              Icon(
                node.group.kind.icon,
                size: 16,
                color: node.group.kind.color(context),
              ),
              Text(
                node.group.name.toUpperCase(),
                style: theme.textTheme.eyebrow.copyWith(
                  color: node.group.kind.color(context),
                ),
              ),
            ],
          ),
        ),
      );
      for (final category in categories) {
        rows.add(
          PickerRow(
            title: category.name,
            leading: CategoryAvatar(
              icon: categoryIcon(category.icon),
              color: Color(category.color),
              size: 32,
            ),
            selected: category.id == widget.selectedId,
            onTap: () => Navigator.pop(context, category.id),
          ),
        );
      }
    }

    return PickerSheet(
      title: l10n.categoryPickerTitle,
      searchHint: l10n.categoryPickerSearchHint,
      onSearch: (value) => setState(() => _query = value),
      footer: widget.showActions
          ? [
              Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _leave(context, Routes.newCategory(widget.kind)),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.editorNewCategory),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _leave(context, Routes.categories),
                    child: Text(l10n.categoryPickerManage),
                  ),
                ],
              ),
            ]
          : const [],
      children: rows.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(l10n.categoryPickerNoResults),
              ),
            ]
          : rows,
    );
  }
}
