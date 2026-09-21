import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/result.dart';
import '../../../core/text/sort_key.dart';
import '../../../core/widgets/picker_sheet.dart';
import '../../../data/models/label.dart';
import '../providers/transactions_controller.dart';
import '../providers/transactions_providers.dart';
import 'transaction_labels_field.dart';

/// Picks the labels of a transaction: the chosen ones as chips on top, then
/// every label with a checkbox and how often it is used. A name that does not
/// exist yet is created from the search field. Returns the chosen ids, `null`
/// when dismissed.
Future<List<String>?> showLabelsPickerSheet(
  BuildContext context,
  List<String> selected,
) => showPickerSheet<List<String>>(
  context,
  (context) => LabelsPickerSheet(selected: selected),
);

class LabelsPickerSheet extends ConsumerStatefulWidget {
  const LabelsPickerSheet({super.key, required this.selected});

  final List<String> selected;

  @override
  ConsumerState<LabelsPickerSheet> createState() => _LabelsPickerSheetState();
}

class _LabelsPickerSheetState extends ConsumerState<LabelsPickerSheet> {
  late var _selected = [...widget.selected];
  final _created = <String>{};
  var _query = '';

  Future<void> _create(String name) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(transactionsControllerProvider.notifier)
        .createLabel(name);
    switch (result) {
      case Ok(:final value):
        setState(() {
          _created.add(value);
          _selected = [..._selected, value];
        });
      case Err():
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorSaveFailed)));
    }
  }

  void _toggle(String id) => setState(
    () => _selected = _selected.contains(id)
        ? [
            for (final other in _selected)
              if (other != id) other,
          ]
        : [..._selected, id],
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final labels = ref.watch(labelsProvider).value ?? const <Label>[];
    final uses = ref.watch(labelUsesProvider).value ?? const <String, int>{};
    final typed = _query.trim();
    final key = sortKey(typed);
    final isNew =
        typed.isNotEmpty && !labels.any((l) => sortKey(l.name) == key);
    // New labels first, as in the design, then the rest by name.
    final matches = [
      for (final label in labels)
        if (_created.contains(label.id)) label,
      for (final label in labels)
        if (!_created.contains(label.id) &&
            (key.isEmpty || sortKey(label.name).contains(key)))
          label,
    ];

    Widget row({
      required Widget leading,
      required Widget title,
      Widget? trailing,
      required VoidCallback onTap,
    }) => InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        constraints: const BoxConstraints(minHeight: 52),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Row(
          spacing: 12,
          children: [
            leading,
            Expanded(child: title),
            ?trailing,
          ],
        ),
      ),
    );

    return PickerSheet(
      title: l10n.fieldLabels,
      header: _selected.isEmpty
          ? null
          : LabelChips(
              labelIds: _selected,
              names: {for (final label in labels) label.id: label.name},
              onChanged: (ids) => setState(() => _selected = ids),
            ),
      searchHint: l10n.labelsPickerSearchHint,
      onSearch: (value) => setState(() => _query = value),
      onSearchSubmitted: (value) {
        if (isNew) _create(value.trim());
      },
      footer: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.pop(context, _selected),
            child: Text(l10n.labelsPickerDone(_selected.length)),
          ),
        ),
      ],
      children: [
        if (isNew)
          row(
            leading: const Icon(Icons.add),
            title: Text(l10n.labelsPickerCreate(typed)),
            onTap: () => _create(typed),
          ),
        for (final label in matches)
          MergeSemantics(
            child: row(
              onTap: () => _toggle(label.id),
              leading: Checkbox(
                // The whole row is the touch target.
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                value: _selected.contains(label.id),
                onChanged: (_) => _toggle(label.id),
              ),
              title: Text(
                label.name,
                style: theme.textTheme.bodyLarge!.copyWith(
                  fontWeight: _selected.contains(label.id)
                      ? FontWeight.w600
                      : null,
                ),
              ),
              trailing: _created.contains(label.id)
                  ? Text(
                      l10n.labelsPickerCreatedNow,
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : Text(
                      l10n.labelsPickerUses(uses[label.id] ?? 0),
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: FinanceColors.of(context).muted,
                      ),
                    ),
            ),
          ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.only(top: 12, bottom: 20),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Text(l10n.labelsPickerNote, style: theme.textTheme.bodySmall),
        ),
      ],
    );
  }
}
