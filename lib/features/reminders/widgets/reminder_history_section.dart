import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/trailing_amount.dart';
import '../../../data/models/transaction.dart';
import 'reminder_section_header.dart';

/// Recorded occurrences listed under "History".
const _listed = 5;

class ReminderHistorySection extends StatelessWidget {
  const ReminderHistorySection({
    super.key,
    required this.recorded,
    required this.onOpen,
  });

  /// Newest first.
  final List<Transaction> recorded;
  final ValueChanged<Transaction> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final income = FinanceColors.of(context).income;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReminderSectionHeader(
          title: l10n.reminderHistory,
          caption: l10n.reminderHistoryCount(recorded.length),
        ),
        if (recorded.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              l10n.reminderHistoryEmpty,
              style: theme.textTheme.bodySmall!.copyWith(fontSize: 13),
            ),
          ),
        for (final (i, transaction) in recorded.take(_listed).indexed) ...[
          if (i > 0) const Divider(),
          InkWell(
            onTap: () => onOpen(transaction),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: TrailingAmount(
                  text: Text(
                    DateFormat.yMMMd(l10n.localeName)
                        .format(transaction.occurredAt),
                    style: theme.textTheme.bodyLarge,
                  ),
                  amount: Text(
                    l10n.reminderRecorded,
                    style: theme.textTheme.bodySmall!.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: income,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
