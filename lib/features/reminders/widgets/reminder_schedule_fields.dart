import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/editor_row.dart';
import '../../../core/widgets/info_note.dart';
import '../../../core/widgets/large_text.dart';
import '../../../core/widgets/segmented_filter.dart';
import '../../../data/enums/reminder_frequency.dart';
import '../../../data/models/reminder_schedule.dart';
import '../models/reminder_labels.dart';
import 'reminder_ends_field.dart';
import 'reminder_section_header.dart';
import 'reminder_stepper.dart';

/// Occurrences listed by "Next dates".
const _previewed = 3;

class ReminderScheduleFields extends StatelessWidget {
  const ReminderScheduleFields({
    super.key,
    required this.schedule,
    required this.isNew,
    required this.today,
    required this.onChanged,
  });

  final ReminderSchedule schedule;

  /// A new reminder asks for its "First due" date, an existing one for the
  /// "Next due".
  final bool isNew;

  /// Midnight today.
  final DateTime today;
  final ValueChanged<ReminderSchedule> onChanged;

  ReminderSchedule _with({
    ReminderFrequency? frequency,
    int? interval,
    DateTime? due,
  }) => ReminderSchedule(
    frequency: frequency ?? schedule.frequency,
    interval: interval ?? schedule.interval,
    startDate: due ?? schedule.startDate,
    nextDueAt: due ?? schedule.nextDueAt,
    endDate: schedule.endDate,
    remainingOccurrences: schedule.remainingOccurrences,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final due = schedule.nextDueAt;
    final once = schedule.frequency == ReminderFrequency.once;
    final dates = schedule.normalized().upcoming.take(_previewed).toList();

    Future<void> pickDue() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: due ?? today,
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
      );
      if (picked == null) return;
      // The time of day, when the reminder has one, stays.
      onChanged(
        _with(
          due: DateTime(
            picked.year,
            picked.month,
            picked.day,
            due?.hour ?? 0,
            due?.minute ?? 0,
          ),
        ),
      );
    }

    final dueRow = EditorRow(
      icon: Icons.calendar_today_outlined,
      label: isNew ? l10n.fieldFirstDue : l10n.fieldNextDue,
      onTap: pickDue,
      child: Text(
        due == null
            ? l10n.actionChoose
            : DateFormat.yMMMd(l10n.localeName).format(due),
      ),
    );
    final every = ReminderStepper(
      label: l10n.reminderEvery,
      value: reminderIntervalLabel(schedule.frequency, schedule.interval, l10n),
      onFewer: schedule.interval > 1
          ? () => onChanged(_with(interval: schedule.interval - 1))
          : null,
      onMore: () => onChanged(_with(interval: schedule.interval + 1)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReminderSectionHeader(title: l10n.reminderSchedule),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Text(l10n.fieldFrequency, style: theme.textTheme.bodySmall),
              SegmentedFilter<ReminderFrequency>(
                options: [
                  for (final frequency in ReminderFrequency.values)
                    (frequency, reminderFrequencyLabel(frequency, 1, l10n)),
                ],
                selected: schedule.frequency,
                onChanged: (frequency) =>
                    onChanged(_with(frequency: frequency)),
              ),
            ],
          ),
        ),
        const Divider(),
        if (once)
          dueRow
        // With large text the stepper and the date no longer fit side by side.
        else if (isLargeText(context)) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: every,
          ),
          const Divider(),
          dueRow,
        ] else
          // Same height, so their hairlines meet.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                Expanded(
                  flex: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: every,
                    ),
                  ),
                ),
                Expanded(flex: 5, child: dueRow),
              ],
            ),
          ),
        if (!once)
          ReminderEndsField(
            endDate: schedule.endDate,
            times: schedule.remainingOccurrences,
            firstDate: due ?? today,
            onChanged: (endDate, times) => onChanged(
              ReminderSchedule(
                frequency: schedule.frequency,
                interval: schedule.interval,
                startDate: schedule.startDate,
                nextDueAt: schedule.nextDueAt,
                endDate: endDate,
                remainingOccurrences: times,
              ),
            ),
          ),
        if (dates.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: InfoNote(
              l10n.reminderNextDates(
                [
                  // The year once, on the last date, unless they differ.
                  for (final date in dates)
                    date == dates.last
                        ? DateFormat.yMMMd(l10n.localeName).format(date)
                        : reminderDate(date, dates.last, l10n),
                ].join(' · '),
              ),
            ),
          ),
      ],
    );
  }
}
