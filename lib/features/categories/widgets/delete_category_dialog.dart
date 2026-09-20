import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/ledger_dialog.dart';
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
  required Category? group,
}) => showDialog<CategoryDeleteChoice>(
  context: context,
  builder: (context) =>
      _DeleteCategoryDialog(category: category, usage: usage, group: group),
);

/// Where the transactions and reminders go.
enum _Target { group, other, none }

class _DeleteCategoryDialog extends ConsumerStatefulWidget {
  const _DeleteCategoryDialog({
    required this.category,
    required this.usage,
    required this.group,
  });

  final Category category;
  final CategoryUsage usage;

  /// The group of [category]; `null` when it is a group itself.
  final Category? group;

  @override
  ConsumerState<_DeleteCategoryDialog> createState() =>
      _DeleteCategoryDialogState();
}

class _DeleteCategoryDialogState extends ConsumerState<_DeleteCategoryDialog> {
  late var _target = widget.group == null ? _Target.none : _Target.group;
  String? _otherId;

  String? get _reassignTo => switch (_target) {
    _Target.group => widget.group!.id,
    _Target.other => _otherId,
    _Target.none => null,
  };

  Future<void> _pickOther() async {
    final id = await showCategoryPickerSheet(
      context,
      kind: widget.category.kind,
      selectedId: _otherId,
      showActions: false,
    );
    // Moving it to itself is not a choice; the sheet cannot hide it.
    if (!mounted || id == null || id == widget.category.id) return;
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
              ? () => Navigator.pop(context, CategoryDeleteChoice(_reassignTo))
              : null,
          child: Text(l10n.actionDelete),
        ),
      ],
    );
  }

  Widget _reassign(AppLocalizations l10n) {
    final all = ref.watch(categoriesProvider).value ?? const <Category>[];
    final chosen = all.where((c) => c.id == _otherId).firstOrNull;
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
            if (target == _Target.other && _otherId == null) _pickOther();
          },
          child: Column(
            children: [
              if (widget.group case final group?)
                RadioListTile<_Target>(
                  contentPadding: EdgeInsets.zero,
                  value: _Target.group,
                  title: Text(l10n.categoryDeleteToGroup(group.name)),
                ),
              RadioListTile<_Target>(
                contentPadding: EdgeInsets.zero,
                value: _Target.other,
                title: Text(l10n.categoryDeleteToOther),
                subtitle: _target == _Target.other
                    ? Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton(
                          onPressed: _pickOther,
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
