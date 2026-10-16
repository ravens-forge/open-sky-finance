import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../app/now.dart';
import '../../../core/l10n.dart';
import '../../reminders/widgets/reminder_notify_switch.dart';
import '../../reminders/widgets/reminder_schedule_fields.dart';
import '../../reminders/widgets/reminder_section_header.dart';
import '../models/transaction_form_values.dart';

/// The reminder form's schedule, automatic posting and notification, in
/// place of the date and time.
class TransactionReminderFields extends ConsumerWidget {
  const TransactionReminderFields({
    super.key,
    required this.values,
    required this.isNew,
    required this.onChanged,
  });

  final TransactionFormValues values;
  final bool isNew;
  final ValueChanged<TransactionFormValues> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReminderScheduleFields(
          schedule: values.schedule,
          isNew: isNew,
          today: ref.watch(todayProvider),
          onChanged: (schedule) =>
              onChanged(values.copyWith(schedule: schedule)),
        ),
        ReminderSectionHeader(title: l10n.assetsAccountOptions),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.reminderAuto),
          subtitle: Text(
            values.autoPost
                ? l10n.reminderAutoOnHint
                : l10n.reminderAutoOffHint,
          ),
          value: values.autoPost,
          onChanged: (on) => onChanged(values.copyWith(autoPost: on)),
        ),
        ReminderNotifySwitch(
          value: values.notify,
          onChanged: (on) => onChanged(values.copyWith(notify: on)),
        ),
        const Divider(),
      ],
    );
  }
}
