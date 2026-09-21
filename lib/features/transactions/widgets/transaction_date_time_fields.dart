import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/editor_row.dart';

/// When the transaction happened, side by side: a date and a time, local wall
/// clock.
class TransactionDateTimeFields extends StatelessWidget {
  const TransactionDateTimeFields({
    super.key,
    required this.dateTime,
    required this.onChanged,
  });

  final DateTime dateTime;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    Future<void> pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: dateTime,
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
      );
      if (picked == null) return;
      onChanged(
        DateTime(
          picked.year,
          picked.month,
          picked.day,
          dateTime.hour,
          dateTime.minute,
        ),
      );
    }

    Future<void> pickTime() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(dateTime),
      );
      if (picked == null) return;
      onChanged(
        DateTime(
          dateTime.year,
          dateTime.month,
          dateTime.day,
          picked.hour,
          picked.minute,
        ),
      );
    }

    return Row(
      spacing: 16,
      children: [
        Expanded(
          child: EditorRow(
            icon: Icons.calendar_today_outlined,
            label: l10n.fieldDate,
            onTap: pickDate,
            child: Text(DateFormat.yMMMd(l10n.localeName).format(dateTime)),
          ),
        ),
        Expanded(
          child: EditorRow(
            icon: Icons.schedule,
            label: l10n.fieldTime,
            onTap: pickTime,
            child: Text(DateFormat.jm(l10n.localeName).format(dateTime)),
          ),
        ),
      ],
    );
  }
}
