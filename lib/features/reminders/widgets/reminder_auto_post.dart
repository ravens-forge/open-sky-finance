import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../providers/reminders_controller.dart';

class ReminderAutoPost extends ConsumerStatefulWidget {
  const ReminderAutoPost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ReminderAutoPost> createState() => _ReminderAutoPostState();
}

class _ReminderAutoPostState extends ConsumerState<ReminderAutoPost> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _post);
    WidgetsBinding.instance.addPostFrameCallback((_) => _post());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    if (!mounted) return;
    final recorded = await ref
        .read(remindersControllerProvider.notifier)
        .postDue();
    if (recorded == 0 || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.remindersAutoRecorded(recorded))),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
