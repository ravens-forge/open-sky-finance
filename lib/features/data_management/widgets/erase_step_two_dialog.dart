import 'package:flutter/material.dart';

import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/destructive_button.dart';
import '../../../core/widgets/ledger_dialog.dart';

/// Step 2 of "Erase all data". `true` to erase.
Future<bool> showEraseStepTwoDialog(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => const EraseStepTwoDialog(),
    ) ??
    false;

/// The last chance: Erase stays disabled until the user checks that they
/// understand. Cancel is the default action.
class EraseStepTwoDialog extends StatefulWidget {
  const EraseStepTwoDialog({super.key});

  @override
  State<EraseStepTwoDialog> createState() => _EraseStepTwoDialogState();
}

class _EraseStepTwoDialogState extends State<EraseStepTwoDialog> {
  bool _understood = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final line = BorderSide(color: theme.colorScheme.outlineVariant);
    return LedgerDialog(
      eyebrow: l10n.eraseStepTwo,
      title: l10n.eraseStepTwoTitle,
      body: l10n.eraseStepTwoBody,
      extra: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: line, bottom: line),
        ),
        child: CheckboxListTile(
          value: _understood,
          onChanged: (on) => setState(() => _understood = on ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          horizontalTitleGap: 4,
          activeColor: FinanceColors.of(context).expense,
          title: Text(l10n.eraseUnderstand, style: theme.textTheme.bodyLarge),
        ),
      ),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.actionCancel),
        ),
        DestructiveButton(
          onPressed: _understood ? () => Navigator.pop(context, true) : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              const Icon(Icons.delete_outline, size: 18),
              Text(l10n.eraseAction),
            ],
          ),
        ),
      ],
    );
  }
}
