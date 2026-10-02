import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../settings/widgets/settings_section.dart';
import '../../settings/widgets/settings_switch_row.dart';
import '../providers/budget_alerts_controller.dart';
import 'notification_permission.dart';

/// Budget alerts. Reminders notify one by one ("Notify me").
class NotificationsSettings extends ConsumerWidget {
  const NotificationsSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final alerts = ref.watch(budgetAlertsControllerProvider).value ?? false;
    return SettingsSection(
      title: l10n.settingsNotifications,
      children: [
        SettingsSwitchRow(
          icon: Icons.pie_chart_outline,
          title: l10n.settingsBudgetAlerts,
          subtitle: l10n.settingsBudgetAlertsHint,
          value: alerts,
          onChanged: (on) async {
            if (on && !await askNotificationPermission(context, ref)) return;
            await ref
                .read(budgetAlertsControllerProvider.notifier)
                .setEnabled(on);
          },
        ),
      ],
    );
  }
}
