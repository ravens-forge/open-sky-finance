import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_placeholder.dart';
import '../../../data/enums/category_kind.dart';
import '../../../data/models/category.dart';
import '../providers/categories_providers.dart';
import '../widgets/category_kind_tab.dart';

/// Expenses and Income tabs, each with its groups and the categories inside
/// them. The + in the top bar creates a category of the open tab's type.
class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(
    length: CategoryKind.values.length,
    vsync: this,
  );

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pageCategories),
        actions: [
          IconButton(
            tooltip: l10n.editorNewCategory,
            icon: const Icon(Icons.add),
            onPressed: () => context.push(
              Routes.newCategory(CategoryKind.values[_tabs.index]),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          // The theme aligns the scrollable main tabs to the start; these two
          // share the width instead.
          tabAlignment: TabAlignment.fill,
          tabs: [
            for (final kind in CategoryKind.values)
              Tab(
                text: l10n.categoriesTab(
                  kind.label(l10n),
                  _groupCount(categories.value ?? const [], kind),
                ),
              ),
          ],
        ),
      ),
      body: switch (categories) {
        AsyncData(:final value) => TabBarView(
          controller: _tabs,
          children: [
            for (final kind in CategoryKind.values)
              CategoryKindTab(kind: kind, all: value),
          ],
        ),
        AsyncError() => Center(child: EmptyState(title: l10n.errorLoadFailed)),
        _ => PagePlaceholder(label: l10n.pageCategories),
      },
    );
  }

  int _groupCount(List<Category> all, CategoryKind kind) =>
      all.where((c) => c.isGroup && c.kind == kind).length;
}
