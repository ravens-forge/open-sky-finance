import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/backup/models/auto_backup_result.dart';
import '../providers/auto_backup_controller.dart';
import 'auto_backup_flow.dart';

/// Makes the due automatic backup when the app is opened and when it is
/// left; says so when the folder turns out unreachable while it is open.
class AutoBackupRunner extends ConsumerStatefulWidget {
  const AutoBackupRunner({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AutoBackupRunner> createState() => _AutoBackupRunnerState();
}

class _AutoBackupRunnerState extends ConsumerState<AutoBackupRunner> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => _run(visible: true),
      // The last moment the app surely still runs once it is left.
      onHide: () => _run(visible: false),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _run(visible: true));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _run({required bool visible}) async {
    if (!mounted) return;
    final controller = ref.read(autoBackupControllerProvider.notifier);
    final result = await controller.runIfDue();
    if (result != AutoBackupResult.paused || !visible || !mounted) return;
    final folder = (await controller.read()).folder;
    if (!mounted) return;
    final choose = await showAutoBackupPausedDialog(
      context,
      folder?.name ?? '',
    );
    if (choose && mounted) await chooseAutoBackupFolder(context, ref);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
