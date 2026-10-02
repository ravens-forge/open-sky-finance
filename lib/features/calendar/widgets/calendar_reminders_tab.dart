import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/now.dart';
import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_placeholder.dart';
import '../../assets_accounts/providers/assets_account_detail_providers.dart';
import '../../assets_accounts/providers/assets_accounts_providers.dart';
import '../../reminders/models/reminder_labels.dart';
import '../../reminders/providers/reminders_controller.dart';
import '../../reminders/widgets/record_reminder.dart';
import '../../reminders/widgets/reminder_list_row.dart';
import '../../shell/widgets/page_load_error.dart';
import '../models/calendar_period.dart';
import '../providers/calendar_providers.dart';

/// The reminders due in the period: Record and Skip on the one due now,
/// "Recorded" on those already recorded.
class CalendarRemindersTab extends ConsumerWidget {
  const CalendarRemindersTab({super.key, required this.period});

  final CalendarPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final occurrences = ref.watch(calendarRemindersProvider(period));
    final categories = ref.watch(categoriesByIdProvider);
    final accounts = ref.watch(assetsAccountsProvider);
    final today = ref.watch(todayProvider);

    return switch ((occurrences, categories, accounts)) {
      (AsyncError(), _, _) ||
      (_, AsyncError(), _) ||
      (_, _, AsyncError()) => PageLoadError(
        providers: [
          calendarRemindersProvider(period),
          categoriesByIdProvider,
          assetsAccountsProvider,
        ],
      ),
      (AsyncValue(value: []), _, _) => EmptyState(
        title: l10n.calendarNoReminders,
      ),
      (
        AsyncValue(value: final occurrences?),
        AsyncValue(value: final categories?),
        AsyncValue(value: final accounts?),
      ) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final o in occurrences) ...[
              ReminderListRow(
                reminder: o.reminder,
                categories: categories,
                assetsAccounts: {for (final a in accounts) a.id: a},
                today: today,
                occurrence: o.due,
                recorded: o.recorded != null,
                onRecord: o.isNext && reminderIsDue(o.reminder, today)
                    ? () => recordReminder(context, ref, o.reminder)
                    : null,
                onSkip: o.isNext && reminderIsDue(o.reminder, today)
                    ? () => ref
                          .read(remindersControllerProvider.notifier)
                          .skip(o.reminder.id)
                    : null,
                onTap: () => context.push(Routes.reminder(o.reminder.id)),
              ),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
            ],
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                l10n.calendarRemindersNote,
                style: theme.textTheme.bodySmall!.copyWith(fontSize: 13),
              ),
            ),
          ],
        ),
      _ => PagePlaceholder(label: l10n.pageCalendar, rows: 3),
    };
  }
}
