import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/dates/wall_clock.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/category_avatar.dart';
import '../../../core/widgets/ledger_chip.dart';
import '../../../data/enums/transaction_type.dart';
import '../../../data/models/reminder.dart';

/// A reminder's title, due date (with "Overdue" once past) and signed amount.
class UpcomingReminderRow extends StatelessWidget {
  const UpcomingReminderRow({
    super.key,
    required this.reminder,
    required this.onTap,
  });

  final Reminder reminder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final due = reminder.schedule.nextDueAt!;
    final overdue = due.isBefore(startOfDay(DateTime.now()));
    final transfer = reminder.type == TransactionType.transfer;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          spacing: 12,
          children: [
            CategoryAvatar(
              icon: Icons.repeat,
              color: theme.colorScheme.primary,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    reminder.title.isEmpty
                        ? reminder.type.label(l10n)
                        : reminder.title,
                    style: theme.textTheme.rowTitle,
                  ),
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        l10n.homeReminderDue(
                          DateFormat.MMMd(l10n.localeName).format(due),
                        ),
                        style: theme.textTheme.rowSubtitle,
                      ),
                      if (overdue) LedgerChip.overdue(l10n.chipOverdue),
                    ],
                  ),
                ],
              ),
            ),
            AmountText(
              reminder.amount.micros,
              currency: reminder.amount.currency,
              amountStyle: transfer ? AmountStyle.transfer : AmountStyle.signed,
              style: theme.textTheme.rowAmount,
            ),
          ],
        ),
      ),
    );
  }
}
