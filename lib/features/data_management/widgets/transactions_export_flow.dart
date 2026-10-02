import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/result.dart';
import '../../../core/widgets/action_sheet.dart';
import '../providers/transactions_import_controller.dart';

/// Export CSV: Save to… or Share… the transactions, then a snack bar with
/// the file name. [context] anchors the share sheet on tablets.
Future<void> exportTransactionsCsv(BuildContext context, WidgetRef ref) {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final controller = ref.read(transactionsImportControllerProvider.notifier);
  final box = context.findRenderObject() as RenderBox?;
  void report(Result<String?, AppError> result) {
    final message = switch (result) {
      Ok(value: final name?) => l10n.exportCsvDone(name),
      Ok() => null,
      Err() => l10n.exportCsvFailed,
    };
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  return showActionSheet(
    context,
    title: l10n.exportCsv,
    actions: [
      SheetAction(
        Icons.folder_outlined,
        l10n.backupsSaveTo,
        () async => report(await controller.saveCsv()),
      ),
      SheetAction(
        Icons.share_outlined,
        l10n.backupsShare,
        () async => report(
          await controller.shareCsv(
            origin: box == null
                ? null
                : box.localToGlobal(Offset.zero) & box.size,
          ),
        ),
      ),
    ],
  );
}
