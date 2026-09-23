import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/result.dart';
import '../providers/backup_controller.dart';

/// Save to…, then a snack bar with the file name.
Future<void> saveBackup(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final result = await ref.read(backupControllerProvider.notifier).saveTo();
  _report(messenger, l10n, result, l10n.backupSaved);
}

/// Share…, anchored at [context]'s widget on tablets, then a snack bar with
/// the file name.
Future<void> shareBackup(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final box = context.findRenderObject() as RenderBox?;
  final result = await ref
      .read(backupControllerProvider.notifier)
      .share(
        origin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );
  _report(messenger, l10n, result, l10n.backupShared);
}

void _report(
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
  Result<String?, AppError> result,
  String Function(String fileName) done,
) {
  final message = switch (result) {
    Ok(value: final fileName?) => done(fileName),
    Ok() => null,
    Err() => l10n.backupFailed,
  };
  if (message != null) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}
