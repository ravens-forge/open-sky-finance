import 'package:flutter/material.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/ledger_dialog.dart';
import '../../../data/models/assets_account_usage.dart';
import '../models/delete_choice.dart';

/// Says how much is deleted permanently and, when it has transactions,
/// offers to hide it instead. `null` when cancelled.
Future<DeleteChoice?> showDeleteAssetsAccountDialog(
  BuildContext context, {
  required String name,
  required AssetsAccountUsage usage,
}) {
  final l10n = context.l10n;
  final theme = Theme.of(context);
  final hasHistory = usage.transactions > 0;
  return showLedgerDialog<DeleteChoice>(
    context: context,
    kind: DialogKind.warning,
    title: l10n.assetsAccountDeleteTitle(name),
    body: [
      if (hasHistory)
        l10n.assetsAccountDeleteTransactions(usage.transactions, usage.trashed),
      if (usage.reminders > 0)
        l10n.assetsAccountDeleteReminders(usage.reminders),
      l10n.assetsAccountDeleteNoUndo,
    ].join(' '),
    extra: hasHistory
        ? Builder(
            builder: (context) => Container(
              padding: const EdgeInsets.all(12),
              color: theme.colorScheme.surfaceContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Text(
                    l10n.assetsAccountHideInstead,
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    l10n.assetsAccountHideInsteadNote,
                    style: theme.textTheme.bodySmall,
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, DeleteChoice.hide),
                    child: Text(l10n.assetsAccountHide(name)),
                  ),
                ],
              ),
            ),
          )
        : null,
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
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(context, DeleteChoice.delete),
          child: Text(l10n.actionDelete),
        ),
      ),
    ],
  );
}
