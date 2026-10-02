import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../data/enums/reminder_status.dart';
import '../../../data/models/reminder.dart';
import '../../../services/notifications/models/local_notice.dart';

/// iOS keeps at most 64 pending notifications; the soonest ones go first.
const maxReminderNotices = 50;

/// One notification at the next due date of each active reminder with
/// "Notify me" on, soonest first. Overdue ones are left to the Reminders
/// page. No amounts: the lock screen may show the title.
List<LocalNotice> reminderNotices(
  List<Reminder> reminders,
  DateTime now,
  AppLocalizations l10n,
) {
  final due = [
    for (final r in reminders)
      if (r.notify && r.status == ReminderStatus.active)
        if (r.schedule.nextDueAt case final at? when at.isAfter(now)) (r, at),
  ]..sort((a, b) => a.$2.compareTo(b.$2));
  return [
    for (final (i, (r, at)) in due.take(maxReminderNotices).indexed)
      LocalNotice(
        id: i,
        title: r.title.isEmpty ? r.type.label(l10n) : r.title,
        body: l10n.reminderNoticeBody,
        route: Routes.reminder(r.id),
        at: at,
      ),
  ];
}
