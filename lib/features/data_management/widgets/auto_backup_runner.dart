import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../services/backup/models/auto_backup_result.dart';
import '../providers/auto_backup_controller.dart';
import 'auto_backup_flow.dart';

/// Makes the due automatic backup when the app is opened and when it is
/// left; says so when the folder turns out unreachable while it is open.
class AutoBackupRunner extends HookConsumerWidget {
  const AutoBackupRunner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future<void> run({required bool visible}) async {
        if (!context.mounted) return;
        final controller = ref.read(autoBackupControllerProvider.notifier);
        final result = await controller.runIfDue();
        if (result != AutoBackupResult.paused || !visible) return;
        if (!context.mounted) return;
        final folder = (await controller.read()).folder;
        if (!context.mounted) return;
        final choose = await showAutoBackupPausedDialog(
          context,
          folder?.name ?? '',
        );
        if (choose && context.mounted) {
          await chooseAutoBackupFolder(context, ref);
        }
      }

      final lifecycle = AppLifecycleListener(
        onResume: () => run(visible: true),
        // The last moment the app surely still runs once it is left.
        onHide: () => run(visible: false),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => run(visible: true));
      return lifecycle.dispose;
    }, const []);
    return child;
  }
}
