import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/info_note.dart';
import '../../../core/widgets/warning_banner.dart';
import '../../../services/bluecoins/models/bluecoins_note.dart';
import '../../../services/bluecoins/models/bluecoins_skip_reason.dart';
import '../models/bluecoins_preview.dart';
import '../models/restore_choice.dart';
import '../widgets/backup_file_row.dart';
import '../widgets/bluecoins_balances.dart';
import '../widgets/bluecoins_report_labels.dart';
import '../widgets/file_size_label.dart';
import '../widgets/restore_preview_actions.dart';
import '../widgets/restore_preview_heading.dart';
import '../widgets/restore_preview_row.dart';

class BluecoinsPreviewPage extends StatelessWidget {
  const BluecoinsPreviewPage({super.key, required this.preview});

  final BluecoinsPreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final count = NumberFormat.decimalPattern(l10n.localeName).format;
    final month = DateFormat.yMMM(l10n.localeName).format;
    final file = preview.file;
    final snapshot = file.import.snapshot;
    final report = file.import.report;
    void pop([RestoreChoice? choice]) => Navigator.pop(context, choice);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bluecoinsImport)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          BackupFileRow(
            name: file.fileName,
            subtitle: l10n.bluecoinsReady(fileSizeLabel(l10n, file.size)),
            onChange: () => pop(RestoreChoice.change),
          ),
          const SizedBox(height: 16),
          WarningBanner(
            lead: l10n.bluecoinsReplaceLead,
            text: l10n.bluecoinsReplaceNote,
          ),
          RestorePreviewHeading(l10n.bluecoinsWhatWillBeImported),
          RestorePreviewRow(
            l10n.pageAssetsAccounts,
            count(snapshot.assetsAccounts.length),
          ),
          RestorePreviewRow(
            l10n.bluecoinsGroupsCategories,
            l10n.bluecoinsCounts2(
              count(snapshot.categoryGroups.length),
              count(snapshot.categories.length),
            ),
          ),
          RestorePreviewRow(l10n.pageLabels, count(snapshot.labels.length)),
          RestorePreviewRow(l10n.pageTransactions, count(preview.transactions)),
          RestorePreviewRow(l10n.bluecoinsTransfers, count(preview.transfers)),
          RestorePreviewRow(l10n.bluecoinsDates, switch ((
            preview.first,
            preview.last,
          )) {
            (final first?, final last?) => l10n.bluecoinsDateRange(
              month(first),
              month(last),
            ),
            _ => l10n.restoreNoTransactions,
          }),
          RestorePreviewHeading(
            l10n.bluecoinsBalances,
            caption: l10n.bluecoinsCompare,
          ),
          BluecoinsBalances(preview.balances),
          if (report.skipped.isNotEmpty) ...[
            RestorePreviewHeading(
              l10n.bluecoinsSkipped,
              caption: l10n.bluecoinsItems(report.skippedTotal),
              warning: true,
            ),
            for (final reason in BluecoinsSkipReason.values)
              if (report.skipped[reason] case final n?)
                RestorePreviewRow(bluecoinsSkipLabel(l10n, reason), count(n)),
          ],
          if (report.notes.isNotEmpty) ...[
            RestorePreviewHeading(l10n.bluecoinsChanged),
            for (final note in BluecoinsNote.values)
              if (report.notes[note] case final n?)
                RestorePreviewRow(bluecoinsNoteLabel(l10n, note), count(n)),
          ],
          const SizedBox(height: 24),
          InfoNote(l10n.bluecoinsNotAffiliated, icon: Icons.info_outline),
        ],
      ),
      bottomNavigationBar: RestorePreviewActions(
        onCancel: pop,
        onRestore: () => pop(RestoreChoice.restore),
        label: l10n.bluecoinsAction,
      ),
    );
  }
}
