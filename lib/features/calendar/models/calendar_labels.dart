import 'package:intl/intl.dart';

import '../../../core/dates/wall_clock.dart';
import '../../../core/labels.dart';
import '../../../data/enums/transaction_type.dart';
import '../../../core/l10n.dart';
import 'calendar_mode.dart';
import 'calendar_period.dart';

/// "Thursday, September 17", "Sep 14 – Sep 20, 2026" or "September 2026".
String calendarPeriodTitle(CalendarPeriod period, AppLocalizations l10n) {
  final locale = l10n.localeName;
  if (period.mode == CalendarMode.month) {
    return capitalizeFirst(DateFormat.yMMMM(locale).format(period.start));
  }
  if (period.isSingleDay) {
    return capitalizeFirst(DateFormat.MMMMEEEEd(locale).format(period.start));
  }
  final sameYear = period.start.year == period.lastDay.year;
  return l10n.calendarPeriodRange(
    (sameYear ? DateFormat.MMMd(locale) : DateFormat.yMMMd(locale)).format(
      period.start,
    ),
    DateFormat.yMMMd(locale).format(period.lastDay),
  );
}

/// What a day cell reads aloud: "September 15, Income, Expense, reminder
/// due".
String calendarDaySemantics(
  DateTime day,
  List<TransactionType> types,
  bool reminderDue,
  AppLocalizations l10n,
) => [
  DateFormat.MMMMd(l10n.localeName).format(day),
  for (final type in types) type.label(l10n),
  if (reminderDue) l10n.calendarReminderDue,
].join(', ');
