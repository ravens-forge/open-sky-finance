import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/editor_row.dart';
import '../../../core/widgets/ledger_chip.dart';
import '../../../data/models/label.dart';
import '../providers/transactions_providers.dart';
import 'labels_picker_sheet.dart';

/// The labels of the transaction as chips, each one removable with its ✕,
/// plus "+ Add", which opens the picker (where a new label can be created).
class TransactionLabelsField extends ConsumerWidget {
  const TransactionLabelsField({
    super.key,
    required this.labelIds,
    required this.onChanged,
  });

  final List<String> labelIds;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final names = {
      for (final label in ref.watch(labelsProvider).value ?? const <Label>[])
        label.id: label.name,
    };

    return EditorRow(
      icon: Icons.sell_outlined,
      label: l10n.fieldLabels,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: LabelChips(
          labelIds: labelIds,
          names: names,
          onChanged: onChanged,
          trailing: LedgerChip.add(
            l10n.actionAdd,
            icon: Icons.add,
            onPressed: () async {
              final picked = await showLabelsPickerSheet(context, labelIds);
              if (picked != null) onChanged(picked);
            },
          ),
        ),
      ),
    );
  }
}

/// Removable chips of [labelIds] (the ✕ removes one), for the editor and the
/// labels picker.
class LabelChips extends StatelessWidget {
  const LabelChips({
    super.key,
    required this.labelIds,
    required this.names,
    required this.onChanged,
    this.trailing,
  });

  final List<String> labelIds;
  final Map<String, String> names;
  final ValueChanged<List<String>> onChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final id in labelIds)
          if (names[id] case final name?)
            Semantics(
              label: l10n.labelRemove(name),
              button: true,
              excludeSemantics: true,
              child: LedgerChip.label(
                name,
                trailingIcon: Icons.close,
                onPressed: () => onChanged([
                  for (final other in labelIds)
                    if (other != id) other,
                ]),
              ),
            ),
        ?trailing,
      ],
    );
  }
}
