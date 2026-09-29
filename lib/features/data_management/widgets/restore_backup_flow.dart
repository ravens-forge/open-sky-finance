import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../../../core/result.dart';
import '../../../core/widgets/progress_dialog.dart';
import '../models/restore_choice.dart';
import '../pages/restore_preview_page.dart';
import '../providers/backup_controller.dart';
import 'restore_error_dialog.dart';

/// Restore from file…: the system open dialog, a check of the whole file,
/// the preview (where another file can be picked), then the restore behind a
/// progress dialog without Cancel. Ends on Home, or on an error dialog when
/// nothing changed.
Future<void> restoreFromFile(BuildContext context, WidgetRef ref) async {
  final controller = ref.read(backupControllerProvider.notifier);
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);

  var choice = RestoreChoice.change;
  while (choice == RestoreChoice.change) {
    final file = await FilePicker.pickFile();
    if (file == null || !context.mounted) return;
    final loaded = await withProgressDialog(
      context,
      title: l10n.restoreReadingTitle,
      body: l10n.restoreReadingBody,
      task: () => controller.load(file),
    );
    if (!context.mounted) return;
    switch (loaded) {
      case Err(:final error):
        return showRestoreErrorDialog(context, error);
      case Ok(value: final preview):
        final picked = await navigator.push<RestoreChoice>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => RestorePreviewPage(preview: preview),
          ),
        );
        if (picked == null || !context.mounted) return;
        choice = picked;
        if (choice != RestoreChoice.restore) continue;
        final restored = await withProgressDialog(
          context,
          title: l10n.restoringTitle,
          body: l10n.restoringBody,
          task: () => controller.restore(preview.backup.snapshot),
        );
        if (!context.mounted) return;
        if (restored case Err(:final error)) {
          return showRestoreErrorDialog(context, error);
        }
        messenger.showSnackBar(SnackBar(content: Text(l10n.restoreDone)));
        context.go(Routes.home);
    }
  }
}
