import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../../../core/result.dart';
import '../../../core/widgets/progress_dialog.dart';
import '../models/restore_choice.dart';
import '../pages/bluecoins_preview_page.dart';
import '../providers/bluecoins_import_controller.dart';
import 'bluecoins_error_dialog.dart';

/// Import from Bluecoins: the system open dialog (any file type, since many
/// pickers do not know `.fydb`), a check of the whole file, the preview
/// (where another file can be picked), then the import behind a progress
/// dialog without Cancel. Ends on Home, or on an error dialog when nothing
/// changed.
Future<void> importFromBluecoins(BuildContext context, WidgetRef ref) async {
  final controller = ref.read(bluecoinsImportControllerProvider.notifier);
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);

  var choice = RestoreChoice.change;
  while (choice == RestoreChoice.change) {
    final file = await FilePicker.pickFile();
    if (file == null || !context.mounted) return;
    final loaded = await withProgressDialog(
      context,
      title: l10n.bluecoinsReadingTitle,
      body: l10n.bluecoinsReadingBody,
      task: () => controller.load(file),
    );
    if (!context.mounted) return;
    switch (loaded) {
      case Err(:final error):
        return showBluecoinsErrorDialog(context, error);
      case Ok(value: final preview):
        final picked = await navigator.push<RestoreChoice>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => BluecoinsPreviewPage(preview: preview),
          ),
        );
        if (picked == null || !context.mounted) return;
        choice = picked;
        if (choice != RestoreChoice.restore) continue;
        final imported = await withProgressDialog(
          context,
          title: l10n.bluecoinsImportingTitle,
          body: l10n.restoringBody,
          task: () => controller.import(preview.file.import.snapshot),
        );
        if (!context.mounted) return;
        if (imported case Err(:final error)) {
          return showBluecoinsErrorDialog(context, error);
        }
        messenger.showSnackBar(SnackBar(content: Text(l10n.bluecoinsDone)));
        context.go(Routes.home);
    }
  }
}
