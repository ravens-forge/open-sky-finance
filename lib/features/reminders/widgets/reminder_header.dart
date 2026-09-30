import 'package:flutter/material.dart';

import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/category_avatar.dart';
import '../../../core/widgets/category_icons.dart';
import '../../../core/widgets/trailing_amount.dart';
import '../../../data/enums/transaction_type.dart';
import '../../../data/models/category.dart';
import '../../../data/models/reminder.dart';
import '../models/reminder_labels.dart';

class ReminderHeader extends StatelessWidget {
  const ReminderHeader({
    super.key,
    required this.reminder,
    required this.category,
    required this.today,
  });

  final Reminder reminder;
  final Category? category;

  /// Midnight today.
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final finance = FinanceColors.of(context);
    final r = reminder;
    final transfer = r.type == TransactionType.transfer;
    final due = reminderDueText(r, today, l10n);
    final overdue = reminderIsDue(r, today);
    return Container(
      padding: const EdgeInsets.only(top: 18, bottom: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: Row(
        spacing: 12,
        children: [
          CategoryAvatar(
            icon: transfer
                ? Icons.swap_horiz
                : category == null
                ? fallbackCategoryIcon
                : categoryIcon(category!.icon),
            color: transfer
                ? finance.transfer
                : Color(category?.color ?? finance.muted.toARGB32()),
          ),
          Expanded(
            child: TrailingAmount(
              text: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    r.title.isEmpty ? r.type.label(l10n) : r.title,
                    style: theme.textTheme.headlineSmall,
                  ),
                  Text(
                    // "Next due" reads wrong before "Was due …" or "Finished".
                    r.schedule.nextDueAt == null || overdue
                        ? due
                        : l10n.reminderNextDue(due),
                    style: theme.textTheme.bodySmall!.copyWith(
                      fontSize: 13,
                      color: overdue ? finance.warning : null,
                    ),
                  ),
                ],
              ),
              amount: AmountText(
                r.amount.micros,
                currency: r.amount.currency,
                amountStyle: transfer
                    ? AmountStyle.transfer
                    : AmountStyle.signed,
                style: theme.textTheme.headlineSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
