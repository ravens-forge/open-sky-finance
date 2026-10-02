import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/ledger_dialog.dart';
import '../../../services/backup/models/auto_backup_result.dart';
import '../providers/auto_backup_controller.dart';

/// Turns automatic backups on (asking for a folder when needed), then says
/// how the first backup went.
Future<void> turnOnAutoBackups(BuildContext context, WidgetRef ref) =>
    _report(context, ref.read(autoBackupControllerProvider.notifier).turnOn());

/// Picks a new folder, then says how the first backup into it went.
Future<void> chooseAutoBackupFolder(BuildContext context, WidgetRef ref) =>
    _report(
      context,
      ref.read(autoBackupControllerProvider.notifier).chooseFolder(),
    );

Future<void> _report(
  BuildContext context,
  Future<AutoBackupResult?> task,
) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final message = switch (await task) {
    AutoBackupResult.done => l10n.autoBackupDone,
    AutoBackupResult.paused => l10n.autoBackupFolderUnusable,
    AutoBackupResult.failed => l10n.backupFailed,
    _ => null,
  };
  if (message != null) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Says automatic backups stopped because [folder] can't be reached;
/// `true` when the user chose "Choose folder" to resume them.
Future<bool> showAutoBackupPausedDialog(
  BuildContext context,
  String folder,
) async {
  final l10n = context.l10n;
  final choose = await showLedgerDialog<bool>(
    context: context,
    kind: DialogKind.warning,
    title: l10n.autoBackupPausedTitle,
    body: l10n.autoBackupPausedBody(folder),
    actions: [
      Builder(
        builder: (dialog) => TextButton(
          onPressed: () => Navigator.pop(dialog, false),
          child: Text(l10n.actionLater),
        ),
      ),
      Builder(
        builder: (dialog) => FilledButton(
          onPressed: () => Navigator.pop(dialog, true),
          child: Text(l10n.autoBackupChooseFolder),
        ),
      ),
    ],
  );
  return choose ?? false;
}
