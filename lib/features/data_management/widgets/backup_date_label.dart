import 'package:intl/intl.dart';

import '../../../core/dates/wall_clock.dart';
import '../../../core/l10n.dart';

/// "Sep 10, 2026 · 9:14 PM".
String backupDateTimeLabel(AppLocalizations l10n, DateTime at) =>
    l10n.backupDateTime(
      DateFormat.yMMMd(l10n.localeName).format(at),
      DateFormat.jm(l10n.localeName).format(at),
    );

/// "Today, 9:12 AM", "Yesterday, 6:40 PM" or [backupDateTimeLabel].
String backupWhenLabel(AppLocalizations l10n, DateTime at, DateTime now) {
  final time = DateFormat.jm(l10n.localeName).format(at);
  final today = startOfDay(now);
  if (!at.isBefore(today)) return l10n.backupToday(time);
  if (!at.isBefore(DateTime(today.year, today.month, today.day - 1))) {
    return l10n.backupYesterday(time);
  }
  return backupDateTimeLabel(l10n, at);
}
