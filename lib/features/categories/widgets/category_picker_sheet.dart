import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../../../core/text/sort_key.dart';
import '../../../core/widgets/category_avatar.dart';
import '../../../core/widgets/category_icons.dart';
import '../../../core/widgets/picker_row.dart';
import '../../../core/widgets/picker_sheet.dart';
import '../../../data/enums/category_kind.dart';
import '../../../data/models/category.dart';
import '../models/category_group_node.dart';
import '../providers/categories_providers.dart';

/// Picks a category of [kind]: groups are selectable as a whole and their
/// categories are listed under them. Hidden ones are left out. Returns the
/// chosen id, `null` when dismissed.
Future<String?> showCategoryPickerSheet(
  BuildContext context, {
  required CategoryKind kind,
  String? selectedId,
  bool showActions = true,
}) => showPickerSheet<String>(
  context,
  (context) => CategoryPickerSheet(
    kind: kind,
    selectedId: selectedId,
    showActions: showActions,
  ),
);

class CategoryPickerSheet extends ConsumerStatefulWidget {
  const CategoryPickerSheet({
    super.key,
    required this.kind,
    this.selectedId,
    this.showActions = true,
  });

  final CategoryKind kind;
  final String? selectedId;

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
    final all = ref.watch(categoriesProvider).value ?? const <Category>[];
    final nodes = groupCategories(all, widget.kind, includeHidden: false);
    final query = sortKey(_query.trim());
    bool matches(String name) => sortKey(name).contains(query);

    final rows = <Widget>[];
    for (final node in nodes) {
      final wholeGroup = query.isEmpty || matches(node.group.name);
      final categories = wholeGroup
          ? node.categories
          : [
              for (final category in node.categories)
                if (matches(category.name)) category,
            ];
      if (!wholeGroup && categories.isEmpty) continue;
      rows.add(
        PickerRow(
          title: node.group.name,
          subtitle: l10n.categoryPickerWholeGroup,
          leading: CategoryAvatar(
            icon: categoryIcon(node.group.icon),
            color: Color(node.group.color!),
          ),
          selected: node.group.id == widget.selectedId,
          onTap: () => Navigator.pop(context, node.group.id),
        ),
      );
      for (final category in categories) {
        rows.add(
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 24),
            child: PickerRow(
              title: category.name,
              leading: CategoryAvatar(
                icon: categoryIcon(category.icon),
                color: Color(node.colorOf(category)),
                size: 32,
              ),
              selected: category.id == widget.selectedId,
              onTap: () => Navigator.pop(context, category.id),
            ),
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
              TextButton(
                onPressed: () => _leave(context, Routes.categories),
                child: Text(l10n.categoryPickerManage),
              ),
              OutlinedButton(
                onPressed: () =>
                    _leave(context, Routes.newCategory(widget.kind)),
                child: Text(l10n.editorNewCategory),
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
