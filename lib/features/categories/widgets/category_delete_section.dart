import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../../../core/result.dart';
import '../../../core/widgets/destructive_button.dart';
import '../../../data/models/category.dart';
import '../../../data/models/category_usage.dart';
import '../providers/categories_controller.dart';
import '../providers/categories_providers.dart';
import 'delete_category_dialog.dart';

/// Delete at the bottom of both editors, with what it takes with it. A group
/// cannot go while it still has categories.
class CategoryDeleteSection extends ConsumerWidget {
  const CategoryDeleteSection({
    super.key,
    required this.category,
    required this.usage,
  });

  final Category category;
  final CategoryUsage usage;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Category? group,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final choice = await showDeleteCategoryDialog(
      context,
      category: category,
      usage: usage,
      group: group,
    );
    if (choice == null) return;
    final result = await ref
        .read(categoriesControllerProvider.notifier)
        .remove(category.id, reassignTo: choice.reassignTo);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        context.go(Routes.categories);
      case Err():
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorDeleteFailed)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final blocked = usage.subcategories > 0;
    final group = ref
        .watch(categoriesProvider)
        .value
        ?.where((c) => c.id == category.parentId)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        DestructiveButton(
          onPressed: blocked ? null : () => _delete(context, ref, group),
          child: Text(
            category.isGroup ? l10n.categoryGroupDelete : l10n.categoryDelete,
          ),
        ),
        Text(switch (blocked) {
          true => l10n.categoryGroupDeleteBlocked(usage.subcategories),
          false when usage.isUnused => l10n.categoryDeleteUnusedNote,
          false => l10n.categoryDeleteNote,
        }, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
