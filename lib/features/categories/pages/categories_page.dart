import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_placeholder.dart';
import '../../../core/widgets/type_selector.dart';
import '../../../data/enums/category_kind.dart';
import '../../../data/models/category_group.dart';
import '../providers/categories_providers.dart';
import '../widgets/category_kind_tab.dart';

/// Income and Expenses, each with its groups and the categories inside them.
/// The + in the top bar creates a category of the chosen type.
class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  var _kind = CategoryKind.income;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final groups = ref.watch(categoryGroupsProvider);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pageCategories),
        actions: [
          IconButton(
            tooltip: l10n.editorNewCategory,
            icon: const Icon(Icons.add),
            onPressed: () => context.push(Routes.newCategory(_kind)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TypeSelector<CategoryKind>(
              options: [
                for (final kind in CategoryKind.values)
                  (
                    kind,
                    l10n.categoriesTab(
                      kind.label(l10n),
                      _count(groups.value ?? const [], kind),
                    ),
                  ),
              ],
              selected: _kind,
              onChanged: (kind) => setState(() => _kind = kind),
            ),
          ),
        ),
      ),
      body: switch ((groups, categories)) {
        (AsyncData(value: final groups), AsyncData(value: final categories)) =>
          CategoryKindTab(
            key: ValueKey(_kind),
            kind: _kind,
            groups: groups,
            categories: categories,
          ),
        (AsyncError(), _) || (_, AsyncError()) => Center(
          child: EmptyState(title: l10n.errorLoadFailed),
        ),
        _ => PagePlaceholder(label: l10n.pageCategories),
      },
    );
  }

  int _count(List<CategoryGroup> groups, CategoryKind kind) =>
      groups.where((g) => g.kind == kind).length;
}
