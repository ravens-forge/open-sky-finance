import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import 'reminder_stepper.dart';

enum _End { never, onDate, afterTimes }

/// Occurrences a reminder gets when "After a number of times" is chosen.
const _defaultTimes = 12;

class ReminderEndsField extends StatelessWidget {
  const ReminderEndsField({
    super.key,
    required this.endDate,
    required this.times,
    required this.firstDate,
    required this.onChanged,
  });

  final DateTime? endDate;
  final int? times;

  /// The next due date: the reminder cannot end before it.
  final DateTime firstDate;

  /// The new end date and number of times.
  final void Function(DateTime? endDate, int? times) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = FinanceColors.of(context).muted;
    final end = endDate != null
        ? _End.onDate
        : times != null
        ? _End.afterTimes
        : _End.never;

    Future<void> pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: endDate ?? firstDate,
        firstDate: firstDate,
        lastDate: DateTime(2100),
      );
      if (picked != null) onChanged(picked, null);
    }

    Widget option(_End value, String title, [String? trailing]) =>
        RadioListTile<_End>(
          contentPadding: EdgeInsets.zero,
          value: value,
          title: Text(title),
          secondary: trailing == null
              ? null
              : Text(
                  trailing,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: end == value ? null : muted,
                  ),
                ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text(l10n.reminderEnds, style: theme.textTheme.bodySmall),
        ),
        RadioGroup<_End>(
          groupValue: end,
          onChanged: (value) {
            switch (value) {
              case _End.onDate:
                pickDate();
              case _End.afterTimes:
                onChanged(null, times ?? _defaultTimes);
              default:
                onChanged(null, null);
            }
          },
          child: Column(
            children: [
              option(_End.never, l10n.reminderEndsNever),
              const Divider(),
              option(
                _End.onDate,
                l10n.reminderEndsOnDate,
                endDate == null
                    ? l10n.reminderPickDate
                    : DateFormat.yMMMd(l10n.localeName).format(endDate!),
              ),
              const Divider(),
              option(
                _End.afterTimes,
                l10n.reminderEndsAfter,
                times == null ? l10n.reminderTimes(_defaultTimes) : null,
              ),
            ],
          ),
        ),
        if (times case final times?)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 52, bottom: 8),
            child: ReminderStepper(
              value: l10n.reminderTimes(times),
              onFewer: times > 1 ? () => onChanged(null, times - 1) : null,
              onMore: () => onChanged(null, times + 1),
            ),
          ),
        const Divider(),
      ],
    );
  }
}
