import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/destructive_button.dart';
import '../../../core/widgets/ledger_dialog.dart';
import '../../../data/models/data_counts.dart';
import '../../home/widgets/section_link.dart';
import 'last_backup_label.dart';

/// Step 1 of "Erase all data": what goes, with real counts, and a way to
/// back up first. `true` to go on to step 2.
Future<bool> showEraseStepOneDialog(
  BuildContext context, {
  required DataCounts counts,
  required DateTime? lastBackup,
}) async {
  final l10n = context.l10n;
  final theme = Theme.of(context);
  final items = [
    l10n.eraseAccountsAndTransactions(
      counts.assetsAccounts,
      counts.transactions,
    ),
    l10n.eraseRemindersBudgetsLabels(
      counts.reminders,
      counts.budgets,
      counts.labels,
    ),
    l10n.eraseCategoriesAndTrash(counts.categories, counts.trashed),
  ];
  final go = await showLedgerDialog<bool>(
    context: context,
    kind: DialogKind.warning,
    title: l10n.eraseTitle,
    body: l10n.eraseIntro,
    extra: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          DefaultTextStyle.merge(
            style: theme.textTheme.bodyMedium!.copyWith(
              height: 1.7,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 18, child: Text('•')),
                Expanded(child: Text(item)),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          color: FinanceColors.of(context).sunken,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.eraseBackupNote} ${lastBackupLabel(l10n, lastBackup)}',
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Builder(
                builder: (dialog) => SectionLink(
                  l10n.eraseBackUpNow,
                  onPressed: () {
                    Navigator.pop(dialog, false);
                    context.push(Routes.backups);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    actions: [
      Builder(
        builder: (dialog) => TextButton(
          autofocus: true,
          onPressed: () => Navigator.pop(dialog, false),
          child: Text(l10n.actionCancel),
        ),
      ),
      Builder(
        builder: (dialog) => DestructiveButton(
          onPressed: () => Navigator.pop(dialog, true),
          child: Text(l10n.actionContinue),
        ),
      ),
    ],
  );
  return go ?? false;
}
