import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class _DeleteCategoryDialog extends ConsumerStatefulWidget {
  const _DeleteCategoryDialog({required this.category, required this.usage});

  final Category category;
  final CategoryUsage usage;

  @override
  ConsumerState<_DeleteCategoryDialog> createState() =>
      _DeleteCategoryDialogState();
}

class _DeleteCategoryDialogState extends ConsumerState<_DeleteCategoryDialog> {
  var _target = _Target.other;
  String? _otherId;

  Future<void> _pickOther(CategoryKind kind) async {
    final id = await showCategoryPickerSheet(
      context,
      kind: kind,
      excludeId: widget.category.id,
      selectedId: _otherId,
      showActions: false,
    );
    if (!mounted || id == null) return;
    setState(() => _otherId = id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final usage = widget.usage;
    final scheme = Theme.of(context).colorScheme;
    final canDelete = _target != _Target.other || _otherId != null;
    return LedgerDialog(
      kind: DialogKind.warning,
      title: l10n.categoryDeleteTitle(widget.category.name),
      body: [
        if (usage.transactions > 0)
          l10n.categoryDeleteTransactions(usage.transactions),
        if (usage.reminders > 0) l10n.categoryDeleteReminders(usage.reminders),
        if (usage.hasBudget) l10n.categoryDeleteBudget,
        l10n.assetsAccountDeleteNoUndo,
      ].join(' '),
      extra: usage.isUnused ? null : _reassign(l10n),
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
                    _target == _Target.other ? _otherId : null,
                  ),
                )
              : null,
          child: Text(l10n.actionDelete),
        ),
      ],
    );
  }

  Widget _reassign(AppLocalizations l10n) {
    final all = ref.watch(categoriesProvider).value ?? const <Category>[];
    final chosen = all.where((c) => c.id == _otherId).firstOrNull;
    final kind = ref
        .watch(categoryGroupsProvider)
        .value
        ?.where((g) => g.id == widget.category.groupId)
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
          groupValue: _target,
          onChanged: (target) {
            setState(() => _target = target ?? _Target.none);
            if (target == _Target.other && _otherId == null && kind != null) {
              _pickOther(kind);
            }
          },
          child: Column(
            children: [
              RadioListTile<_Target>(
                contentPadding: EdgeInsets.zero,
                value: _Target.other,
                title: Text(l10n.categoryDeleteToOther),
                subtitle: _target == _Target.other
                    ? Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton(
                          onPressed: kind == null
                              ? null
                              : () => _pickOther(kind),
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
