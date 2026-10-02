import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../notifications/widgets/notification_permission.dart';

/// "Notify me": a local notification on each due date. Turning it on asks
/// for the permission first.
class ReminderNotifySwitch extends ConsumerWidget {
  const ReminderNotifySwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.reminderNotify),
      subtitle: Text(l10n.reminderNotifyHint),
      value: value,
      onChanged: (on) async {
        if (on && !await askNotificationPermission(context, ref)) return;
        onChanged(on);
      },
    );
  }
}
