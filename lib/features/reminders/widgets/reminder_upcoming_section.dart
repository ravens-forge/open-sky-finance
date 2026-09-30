import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/dates/wall_clock.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/ledger_chip.dart';
import '../../../core/widgets/record_skip_buttons.dart';
import '../../../core/widgets/trailing_amount.dart';
import '../../../data/enums/reminder_status.dart';
import '../../../data/models/reminder.dart';
import 'reminder_section_header.dart';

/// Occurrences listed under "Upcoming".
const _listed = 3;

class ReminderUpcomingSection extends StatelessWidget {
  const ReminderUpcomingSection({
    super.key,
    required this.reminder,
    required this.today,
    required this.onRecord,
    required this.onSkip,
  });

  final Reminder reminder;

  /// Midnight today.
  final DateTime today;
  final VoidCallback onRecord;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final dates = reminder.schedule.upcoming.take(_listed).toList();
    if (dates.isEmpty) return const SizedBox.shrink();
    final active = reminder.status == ReminderStatus.active;

    Widget trailing(int index) {
      if (index == 0 && active) {
        return reminder.autoPost
            ? LedgerChip.label(l10n.chipAutomatic, compact: true)
            : RecordSkipButtons(onRecord: onRecord, onSkip: onSkip);
      }
      final days = daysBetween(today, dates[index]);
      return Text(
        days > 0 ? l10n.reminderInDays(days) : '',
        style: theme.textTheme.bodySmall!.copyWith(fontSize: 13),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReminderSectionHeader(
          title: l10n.reminderUpcoming,
          caption: l10n.reminderUpcomingNext(dates.length),
        ),
        for (final (i, date) in dates.indexed) ...[
          if (i > 0) const Divider(),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: TrailingAmount(
                text: Text(
                  capitalizeFirst(
                    DateFormat.yMMMEd(l10n.localeName).format(date),
                  ),
                  style: theme.textTheme.bodyLarge,
                ),
                amount: trailing(i),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
