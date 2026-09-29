import 'package:flutter/material.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/ledger_dialog.dart';
import '../../../services/bluecoins/models/bluecoins_import_error.dart';

/// Why a Bluecoins file was not imported, that the data was not changed, and
/// what to do next.
Future<void> showBluecoinsErrorDialog(
  BuildContext context,
  BluecoinsImportError error,
) {
  final l10n = context.l10n;
  final theme = Theme.of(context);
  final (title, body) = switch (error) {
    BluecoinsFileTooLarge() => (
      l10n.bluecoinsErrorTitle,
      l10n.bluecoinsErrorTooLarge,
    ),
    BluecoinsCompressed() => (
      l10n.bluecoinsErrorTitle,
      l10n.bluecoinsErrorCompressed,
    ),
    BluecoinsNotABackup() => (
      l10n.bluecoinsErrorTitle,
      l10n.bluecoinsErrorNotABackup,
    ),
    BluecoinsMissingColumns() => (
      l10n.bluecoinsErrorTitle,
      l10n.bluecoinsErrorMissingColumns,
    ),
    BluecoinsDamaged() => (
      l10n.bluecoinsErrorTitle,
      l10n.bluecoinsErrorDamaged,
    ),
    BluecoinsImportFailed() => (
      l10n.bluecoinsFailedTitle,
      l10n.restoreFailedBody,
    ),
  };
  return showLedgerDialog<void>(
    context: context,
    kind: DialogKind.error,
    title: title,
    body: body,
    extra: switch (error) {
      // Names from the Bluecoins format, never data from the file.
      BluecoinsMissingColumns(:final columns) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final column in columns)
            Text(
              column,
              style: theme.textTheme.bodySmall!.copyWith(height: 1.6),
            ),
        ],
      ),
      _ => null,
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
