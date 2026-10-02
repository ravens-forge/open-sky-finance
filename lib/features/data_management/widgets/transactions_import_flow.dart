import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/result.dart';
import '../../../core/widgets/ledger_dialog.dart';
import '../../../core/widgets/progress_dialog.dart';
import '../../../data/models/import_names.dart';
import '../../../services/transactions_import/models/import_file_error.dart';
import '../models/restore_choice.dart';
import '../models/transactions_import_choice.dart';
import '../pages/transactions_import_preview_page.dart';
import '../providers/transactions_import_controller.dart';

/// Import CSV or QIF: the system open dialog, a read of the whole file, the
/// preview (where another file can be picked), then the import behind a
/// progress dialog without Cancel, and what it added. Nothing changes on an
/// error.
Future<void> importTransactionsFile(BuildContext context, WidgetRef ref) async {
  final controller = ref.read(transactionsImportControllerProvider.notifier);
  final l10n = context.l10n;
  final navigator = Navigator.of(context, rootNavigator: true);

  var choice = RestoreChoice.change;
  while (choice == RestoreChoice.change) {
    final file = await FilePicker.pickFile();
    if (file == null || !context.mounted) return;
    final loaded = await withProgressDialog(
      context,
      title: l10n.importReadingTitle,
      body: l10n.importReadingBody,
      task: () => controller.load(file, l10n.localeName),
    );
    if (!context.mounted) return;
    switch (loaded) {
      case Err(:final error):
        return showImportErrorDialog(context, error);
      case Ok(value: final preview):
        final picked = await navigator.push<TransactionsImportChoice>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => TransactionsImportPreviewPage(preview: preview),
          ),
        );
        if (picked == null || !context.mounted) return;
        choice = picked.choice;
        if (choice != RestoreChoice.restore) continue;
        final imported = await withProgressDialog(
          context,
          title: l10n.importingTitle,
          body: l10n.importingBody,
          task: () => controller.import(
            preview,
            names: ImportNames(categoryGroup: l10n.importCategoryGroup),
            assetsAccountId: picked.assetsAccountId,
          ),
        );
        if (!context.mounted) return;
        switch (imported) {
          case Err(:final error):
            return showImportErrorDialog(context, error);
          case Ok(value: final s):
            await showLedgerDialog<void>(
              context: context,
              title: l10n.importDoneTitle(s.transactions),
              body: [
                if (s.assetsAccounts + s.categories + s.labels > 0)
                  l10n.importDoneCreated(
                    s.assetsAccounts,
                    s.categories,
                    s.labels,
                  ),
                if (s.duplicates > 0) l10n.importDoneDuplicates(s.duplicates),
                if (s.invalid > 0) l10n.importDoneInvalid(s.invalid),
                l10n.importDoneSafety,
              ].join('\n\n'),
              actions: [
                Builder(
                  builder: (dialog) => FilledButton(
                    onPressed: () => Navigator.pop(dialog),
                    child: Text(l10n.actionDone),
                  ),
                ),
              ],
            );
        }
    }
  }
}

/// Why a file was not imported, that the data was not changed, and what to
/// do next.
Future<void> showImportErrorDialog(
  BuildContext context,
  ImportFileError error,
) {
  final l10n = context.l10n;
  return showLedgerDialog<void>(
    context: context,
    kind: DialogKind.error,
    title: error == ImportFileError.failed
        ? l10n.importFailedTitle
        : l10n.importErrorTitle,
    body: switch (error) {
      ImportFileError.tooLarge => l10n.importErrorTooLarge,
      ImportFileError.notReadable => l10n.importErrorNotReadable,
      ImportFileError.missingColumns => l10n.importErrorMissingColumns,
      ImportFileError.empty => l10n.importErrorEmpty,
      ImportFileError.failed => l10n.importFailedBody,
    },
    actions: [
      Builder(
        builder: (dialog) => TextButton(
          onPressed: () => Navigator.pop(dialog),
          child: Text(l10n.actionClose),
        ),
      ),
    ],
  );
}
