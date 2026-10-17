import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/result.dart';
import '../../../core/text/sort_key.dart';
import '../../../core/widgets/picker_sheet.dart';
import '../../../data/models/label.dart';
import '../../../data/providers.dart';
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

class LabelsPickerSheet extends HookConsumerWidget {
  const LabelsPickerSheet({super.key, required this.selected});

  final List<String> selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final chosen = useState([...selected]);
    final created = useState(const <String>{});
    final search = useState('');

    Future<void> create(String name) async {
      final messenger = ScaffoldMessenger.of(context);
      final result = await ref.read(labelsRepositoryProvider).save(name: name);
      if (!context.mounted) return;
      switch (result) {
        case Ok(:final value):
          created.value = {...created.value, value};
          chosen.value = [...chosen.value, value];
        case Err():
          messenger.showSnackBar(SnackBar(content: Text(l10n.errorSaveFailed)));
      }
    }

    void toggle(String id) => chosen.value = chosen.value.contains(id)
        ? [
            for (final other in chosen.value)
              if (other != id) other,
          ]
        : [...chosen.value, id];

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final labels = ref.watch(labelsProvider).value ?? const <Label>[];
    final uses = ref.watch(labelUsesProvider).value ?? const <String, int>{};
    final typed = search.value.trim();
    final key = sortKey(typed);
    final isNew =
        typed.isNotEmpty && !labels.any((l) => sortKey(l.name) == key);
    // New labels first, as in the design, then the rest by name.
    final matches = [
      for (final label in labels)
        if (created.value.contains(label.id)) label,
      for (final label in labels)
        if (!created.value.contains(label.id) &&
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
      header: chosen.value.isEmpty
          ? null
          : LabelChips(
              labelIds: chosen.value,
              names: {for (final label in labels) label.id: label.name},
              onChanged: (ids) => chosen.value = ids,
            ),
      searchHint: l10n.labelsPickerSearchHint,
      onSearch: (value) => search.value = value,
      onSearchSubmitted: (value) {
        if (isNew) create(value.trim());
      },
      footer: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.pop(context, chosen.value),
            child: Text(l10n.labelsPickerDone(chosen.value.length)),
          ),
        ),
      ],
      children: [
        if (isNew)
          row(
            leading: const Icon(Icons.add),
            title: Text(l10n.labelsPickerCreate(typed)),
            onTap: () => create(typed),
          ),
        for (final label in matches)
          MergeSemantics(
            child: row(
              onTap: () => toggle(label.id),
              leading: Checkbox(
                // The whole row is the touch target.
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                value: chosen.value.contains(label.id),
                onChanged: (_) => toggle(label.id),
              ),
              title: Text(
                label.name,
                style: theme.textTheme.bodyLarge!.copyWith(
                  fontWeight: chosen.value.contains(label.id)
                      ? FontWeight.w600
                      : null,
                ),
              ),
              trailing: created.value.contains(label.id)
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
