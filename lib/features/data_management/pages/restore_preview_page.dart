import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/warning_banner.dart';
import '../models/restore_choice.dart';
import '../models/restore_preview.dart';
import '../widgets/backup_date_label.dart';
import '../widgets/backup_file_row.dart';
import '../widgets/file_size_label.dart';
import '../widgets/restore_preview_actions.dart';
import '../widgets/restore_preview_heading.dart';
import '../widgets/restore_preview_row.dart';

class RestorePreviewPage extends StatelessWidget {
  const RestorePreviewPage({super.key, required this.preview});

  final RestorePreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final count = NumberFormat.decimalPattern(l10n.localeName).format;
    final backup = preview.backup;
    final snapshot = backup.snapshot;
    final counts = snapshot.counts;
    final current = preview.current;
    final exportedAt = snapshot.exportedAt.toLocal();
    void pop([RestoreChoice? choice]) => Navigator.pop(context, choice);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.restoreTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          BackupFileRow(
            name: backup.fileName,
            subtitle: l10n.restoreValidBackup(fileSizeLabel(l10n, backup.size)),
            onChange: () => pop(RestoreChoice.change),
          ),
          RestorePreviewHeading(l10n.restoreThisBackup),
          RestorePreviewRow(
            l10n.restoreCreated,
            backupDateTimeLabel(l10n, exportedAt),
          ),
          RestorePreviewRow(l10n.restoreAppVersion, snapshot.appVersion),
          RestorePreviewRow(
            l10n.pageAssetsAccounts,
            count(counts.assetsAccounts),
          ),
          RestorePreviewRow(l10n.pageTransactions, count(counts.transactions)),
          RestorePreviewRow(
            l10n.restoreRemindersBudgetsLabels,
            l10n.restoreCounts3(
              count(counts.reminders),
              count(counts.budgets),
              count(counts.labels),
            ),
          ),
          RestorePreviewRow(l10n.restoreInTrash, count(counts.trashed)),
          RestorePreviewHeading(
            l10n.restoreCurrentData,
            caption: l10n.restoreWillBeReplaced,
          ),
          RestorePreviewRow(l10n.pageTransactions, count(current.transactions)),
          RestorePreviewRow(
            l10n.restoreNewestTransaction,
            switch (current.newestTransaction) {
              final newest? => DateFormat.yMMMd(l10n.localeName).format(newest),
              null => l10n.restoreNoTransactions,
            },
          ),
          const SizedBox(height: 16),
          WarningBanner(
            lead: current.addedSince > 0
                ? l10n.restoreLostLead(
                    current.addedSince,
                    DateFormat.MMMd(l10n.localeName).format(exportedAt),
                  )
                : l10n.restoreReplacedLead,
            text: l10n.restoreSafetyNote,
          ),
        ],
      ),
      bottomNavigationBar: RestorePreviewActions(
        onCancel: pop,
        onRestore: () => pop(RestoreChoice.restore),
      ),
    );
  }
}
