import 'package:flutter/material.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/choice_sheet.dart';
import '../../../core/widgets/editor_row.dart';
import '../../../data/enums/reminder_frequency.dart';
import '../../reminders/models/reminder_labels.dart';

/// "Repeat": choosing a frequency creates a reminder from the transaction.
/// [ReminderFrequency.once] is a transaction that does not repeat.
class TransactionRepeatField extends StatelessWidget {
  const TransactionRepeatField({
    super.key,
    required this.frequency,
    required this.future,
    required this.onChanged,
  });

  final ReminderFrequency frequency;

  /// The transaction is dated after today: only the reminder is created.
  final bool future;
  final ValueChanged<ReminderFrequency> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repeats = frequency != ReminderFrequency.once;
    String label(ReminderFrequency frequency) =>
        frequency == ReminderFrequency.once
        ? l10n.repeatNone
        : reminderFrequencyLabel(frequency, 1, l10n);

    return EditorRow(
      icon: Icons.repeat,
      label: l10n.fieldRepeat,
      helper: repeats && future ? l10n.repeatFutureHint : l10n.repeatHint,
      helperColor: repeats && future
          ? Theme.of(context).colorScheme.primary
          : null,
      onTap: () async {
        final picked = await showChoiceSheet<ReminderFrequency>(
          context,
          title: l10n.fieldRepeat,
          options: [
            for (final frequency in ReminderFrequency.values)
              (frequency, label(frequency)),
          ],
          selected: frequency,
        );
        if (picked != null) onChanged(picked);
      },
      child: Text(label(frequency)),
    );
  }
}
