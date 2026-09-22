import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/ledger_dialog.dart';
import '../../../core/widgets/progress_dialog.dart';
import '../providers/erase_controller.dart';
import '../providers/last_backup_provider.dart';
import 'erase_step_one_dialog.dart';
import 'erase_step_two_dialog.dart';

/// "Erase all data": two confirmations, a progress dialog without Cancel,
/// then the Done screen in place of every other screen, or an error dialog
/// when nothing was deleted.
Future<void> eraseAllData(BuildContext context, WidgetRef ref) async {
  final controller = ref.read(eraseControllerProvider.notifier);
  final counts = await controller.counts();
  if (!context.mounted) return;
  final goOn = await showEraseStepOneDialog(
    context,
    counts: counts,
    lastBackup: ref.read(lastBackupProvider).value,
  );
  if (!goOn || !context.mounted) return;
  if (!await showEraseStepTwoDialog(context) || !context.mounted) return;

  final l10n = context.l10n;
  final navigator = Navigator.of(context, rootNavigator: true);
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          ProgressDialog(title: l10n.erasingTitle, body: l10n.erasingBody),
    ),
  );
  final erased = await controller.eraseAll(l10n);
  navigator.pop();
  if (!context.mounted) return;
  if (erased) {
    context.go(Routes.erased);
    return;
  }
  await showLedgerDialog<void>(
    context: context,
    kind: DialogKind.error,
    title: l10n.eraseFailedTitle,
    body: l10n.eraseFailedBody,
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
