import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../../../core/result.dart';
import '../../../core/widgets/destructive_button.dart';
import '../../../core/widgets/ledger_dialog.dart';
import '../../../data/models/category.dart';
import '../../../data/models/category_group.dart';
import '../../../data/models/category_usage.dart';
import '../providers/categories_controller.dart';
import 'delete_category_dialog.dart';

/// Delete at the bottom of both editors, with what it takes with it. A group
/// cannot go while it still holds categories.
class CategoryDeleteSection extends ConsumerWidget {
  const CategoryDeleteSection({
    super.key,
    this.category,
    this.group,
    required this.usage,
  });

  /// Exactly one of the two is set.
  final Category? category;
  final CategoryGroup? group;
  final CategoryUsage usage;

  Future<void> _deleteCategory(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final choice = await showDeleteCategoryDialog(
      context,
      category: category!,
      usage: usage,
    );
    if (choice == null) return;
    final result = await ref
        .read(categoriesControllerProvider.notifier)
        .remove(category!.id, reassignTo: choice.reassignTo);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        context.go(Routes.categories);
      case Err():
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorDeleteFailed)));
    }
  }

  Future<void> _deleteGroup(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showLedgerDialog<bool>(
      context: context,
      kind: DialogKind.warning,
      title: l10n.categoryDeleteTitle(group!.name),
      body: [
        if (usage.hasBudget) l10n.categoryDeleteBudget,
        l10n.assetsAccountDeleteNoUndo,
      ].join(' '),
      actions: [
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel),
          ),
        ),
        Builder(
          builder: (context) => FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.actionDelete),
          ),
        ),
      ],
    );
    if (confirmed != true) return;
    final result = await ref
        .read(categoriesControllerProvider.notifier)
        .removeGroup(group!.id);
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
    final isGroup = group != null;
    final blocked = isGroup && usage.categories > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        DestructiveButton(
          onPressed: blocked
              ? null
              : () => isGroup
                    ? _deleteGroup(context, ref)
                    : _deleteCategory(context, ref),
          child: Text(isGroup ? l10n.categoryGroupDelete : l10n.categoryDelete),
        ),
        Text(switch ((blocked, isGroup)) {
          (true, _) => l10n.categoryGroupDeleteBlocked(usage.categories),
          (false, true) => l10n.categoryGroupDeleteNote,
          (false, false) when usage.isUnused => l10n.categoryDeleteUnusedNote,
          (false, false) => l10n.categoryDeleteNote,
        }, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
