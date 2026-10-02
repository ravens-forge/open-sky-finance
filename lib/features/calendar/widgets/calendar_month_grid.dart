import 'package:flutter/material.dart';

import '../../../core/l10n.dart';
import '../models/calendar_grid.dart';
import '../models/calendar_labels.dart';
import '../models/calendar_markers.dart';
import '../models/calendar_mode.dart';
import '../models/calendar_period.dart';

import 'calendar_day_cell.dart';

/// Weekday initials and the six weeks of [grid], with [period] selected.
class CalendarMonthGrid extends StatelessWidget {
  const CalendarMonthGrid({
    super.key,
    required this.grid,
    required this.period,
    required this.markers,
    required this.today,
    required this.firstDayOfWeek,
    required this.onTap,
  });

  final CalendarGrid grid;
  final CalendarPeriod period;
  final CalendarMarkers markers;
  final DateTime today;
  final int firstDayOfWeek;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // Sunday first.
    final initials = MaterialLocalizations.of(context).narrowWeekdays;
    final days = grid.days;
    final banded =
        period.mode == CalendarMode.week ||
        (period.mode == CalendarMode.range && !period.isSingleDay);

    Widget cell(DateTime day) {
      final selected = period.contains(day);
      final end = day == period.start || day == period.lastDay;
      final types = markers.typesOn(day);
      final reminderDue = markers.reminderDueOn(day);
      return Expanded(
        child: CalendarDayCell(
          day: day,
          semanticsLabel: calendarDaySemantics(day, types, reminderDue, l10n),
          types: types,
          reminderDue: reminderDue,
          outside: !grid.month.contains(day),
          today: day == today,
          selected: selected,
          filled:
              selected &&
              switch (period.mode) {
                CalendarMode.day => true,
                CalendarMode.month => false,
                _ => end,
              },
          bandStart: banded && selected && day != period.start,
          bandEnd: banded && selected && day != period.lastDay,
          onTap: () => onTap(day),
        ),
      );
    }

    // The digits stay inside their 36 px disc.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Column(
        children: [
          ExcludeSemantics(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Text(
                        initials[(firstDayOfWeek + i) % 7],
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          for (var week = 0; week < CalendarGrid.weeks; week++)
            Row(
              children: [for (var i = 0; i < 7; i++) cell(days[week * 7 + i])],
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
