import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/ledger_dialog.dart';
import '../../../data/enums/category_kind.dart';
import '../../../data/models/category.dart';
import '../../../data/models/category_usage.dart';
import '../models/category_delete_choice.dart';
import '../providers/categories_providers.dart';
import 'category_picker_sheet.dart';

/// Confirms deleting [category] and, when transactions or reminders use it,
/// asks where they go. `null` when cancelled.
Future<CategoryDeleteChoice?> showDeleteCategoryDialog(
  BuildContext context, {
  required Category category,
  required CategoryUsage usage,
}) => showDialog<CategoryDeleteChoice>(
  context: context,
  builder: (context) => _DeleteCategoryDialog(category: category, usage: usage),
);

/// Where the transactions and reminders go.
enum _Target { other, none }

class _DeleteCategoryDialog extends HookConsumerWidget {
  const _DeleteCategoryDialog({required this.category, required this.usage});

  final Category category;
  final CategoryUsage usage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final target = useState(_Target.other);
    final otherId = useState<String?>(null);
    final canDelete = target.value != _Target.other || otherId.value != null;
    return LedgerDialog(
      kind: DialogKind.warning,
      title: l10n.categoryDeleteTitle(category.name),
      body: [
        if (usage.transactions > 0)
          l10n.categoryDeleteTransactions(usage.transactions),
        if (usage.reminders > 0) l10n.categoryDeleteReminders(usage.reminders),
        if (usage.hasBudget) l10n.categoryDeleteBudget,
        l10n.assetsAccountDeleteNoUndo,
      ].join(' '),
      extra: usage.isUnused
          ? null
          : _Reassign(category: category, target: target, otherId: otherId),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: canDelete
              ? () => Navigator.pop(
                  context,
                  CategoryDeleteChoice(
                    target.value == _Target.other ? otherId.value : null,
                  ),
                )
              : null,
          child: Text(l10n.actionDelete),
        ),
      ],
    );
  }
}

/// Where the transactions and reminders of [category] go.
class _Reassign extends ConsumerWidget {
  const _Reassign({
    required this.category,
    required this.target,
    required this.otherId,
  });

  final Category category;
  final ValueNotifier<_Target> target;
  final ValueNotifier<String?> otherId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    Future<void> pickOther(CategoryKind kind) async {
      final id = await showCategoryPickerSheet(
        context,
        kind: kind,
        excludeId: category.id,
        selectedId: otherId.value,
        showActions: false,
      );
      if (!context.mounted || id == null) return;
      otherId.value = id;
    }

    final all = ref.watch(categoriesProvider).value ?? const <Category>[];
    final chosen = all.where((c) => c.id == otherId.value).firstOrNull;
    final kind = ref
        .watch(categoryGroupsProvider)
        .value
        ?.where((g) => g.id == category.groupId)
        .firstOrNull
        ?.kind;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.categoryDeleteMoveTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        RadioGroup<_Target>(
          groupValue: target.value,
          onChanged: (value) {
            target.value = value ?? _Target.none;
            if (value == _Target.other &&
                otherId.value == null &&
                kind != null) {
              pickOther(kind);
            }
          },
          child: Column(
            children: [
              RadioListTile<_Target>(
                contentPadding: EdgeInsets.zero,
                value: _Target.other,
                title: Text(l10n.categoryDeleteToOther),
                subtitle: target.value == _Target.other
                    ? Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton(
                          onPressed: kind == null
                              ? null
                              : () => pickOther(kind),
                          child: Text(chosen?.name ?? l10n.actionChoose),
                        ),
                      )
                    : null,
              ),
              RadioListTile<_Target>(
                contentPadding: EdgeInsets.zero,
                value: _Target.none,
                title: Text(l10n.categoryNone),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
