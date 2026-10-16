import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/l10n.dart';
import '../providers/reminders_controller.dart';

class ReminderAutoPost extends HookConsumerWidget {
  const ReminderAutoPost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future<void> post() async {
        if (!context.mounted) return;
        final recorded = await ref
            .read(remindersControllerProvider.notifier)
            .postDue();
        if (recorded == 0 || !context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.remindersAutoRecorded(recorded))),
        );
      }

      final lifecycle = AppLifecycleListener(onResume: post);
      WidgetsBinding.instance.addPostFrameCallback((_) => post());
      return lifecycle.dispose;
    }, const []);
    return child;
  }
}
