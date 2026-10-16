import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/widgets/page_placeholder.dart';
import '../../../core/widgets/type_selector.dart';
import '../../../data/enums/category_kind.dart';
import '../../../data/models/category_group.dart';
import '../providers/categories_providers.dart';
import '../widgets/category_kind_tab.dart';
import '../../shell/widgets/page_load_error.dart';

/// Income and Expenses, each with its groups and the categories inside them.
/// The + in the top bar creates a category of the chosen type.
class CategoriesPage extends HookConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selected = useState(CategoryKind.income);
    final groups = ref.watch(categoryGroupsProvider);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pageCategories),
        actions: [
          IconButton(
            tooltip: l10n.editorNewCategory,
            icon: const Icon(Icons.add),
            onPressed: () => context.push(Routes.newCategory(selected.value)),
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
              selected: selected.value,
              onChanged: (kind) => selected.value = kind,
            ),
          ),
        ),
      ),
      body: switch ((groups, categories)) {
        (
          AsyncValue(value: final groups?),
          AsyncValue(value: final categories?),
        ) =>
          CategoryKindTab(
            key: ValueKey(selected.value),
            kind: selected.value,
            groups: groups,
            categories: categories,
          ),
        (AsyncError(), _) || (_, AsyncError()) => PageLoadError(
          providers: [categoryGroupsProvider, categoriesProvider],
        ),
        _ => PagePlaceholder(label: l10n.pageCategories),
      },
    );
  }

  int _count(List<CategoryGroup> groups, CategoryKind kind) =>
      groups.where((g) => g.kind == kind).length;
}
