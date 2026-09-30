import 'package:flutter/material.dart';

import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/category_icons.dart';
import '../../../core/widgets/reminder_row.dart';
import '../../../data/enums/reminder_status.dart';
import '../../../data/enums/transaction_type.dart';
import '../../../data/models/assets_account.dart';
import '../../../data/models/category.dart';
import '../../../data/models/reminder.dart';
import '../models/reminder_labels.dart';

class ReminderListRow extends StatelessWidget {
  const ReminderListRow({
    super.key,
    required this.reminder,
    required this.categories,
    required this.assetsAccounts,
    required this.today,
    required this.onRecord,
    required this.onSkip,
    required this.onTap,
  });

  final Reminder reminder;
  final Map<String, Category> categories;
  final Map<String, AssetsAccount> assetsAccounts;

  /// Midnight today.
  final DateTime today;
  final VoidCallback onRecord;
  final VoidCallback onSkip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final finance = FinanceColors.of(context);
    final r = reminder;
    final category = categories[r.categoryId];
    final account = assetsAccounts[r.assetsAccountId]?.name ?? '';
    final transfer = r.type == TransactionType.transfer;
    final active = r.status == ReminderStatus.active;
    final manual = active && !r.autoPost;

    return ReminderRow(
      icon: transfer
          ? Icons.swap_horiz
          : category == null
          ? fallbackCategoryIcon
          : categoryIcon(category.icon),
      iconColor: transfer
          ? finance.transfer
          : Color(category?.color ?? finance.muted.toARGB32()),
      title: r.title.isEmpty ? r.type.label(l10n) : r.title,
      schedule: l10n.reminderDetails(
        reminderFrequencyLabel(r.schedule.frequency, r.schedule.interval, l10n),
        transfer
            ? l10n.transferFromTo(
                account,
                assetsAccounts[r.transfer!.assetsAccountId]?.name ?? '',
              )
            : l10n.transactionSubtitle(
                category?.name ?? l10n.categoryNone,
                account,
              ),
      ),
      due: reminderDueText(r, today, l10n),
      overdue: reminderIsDue(r, today),
      automatic: active && r.autoPost,
      amount: AmountText(
        r.amount.micros,
        currency: r.amount.currency,
        amountStyle: transfer ? AmountStyle.transfer : AmountStyle.signed,
      ),
      onRecord: manual ? onRecord : null,
      onSkip: manual ? onSkip : null,
      onTap: onTap,
    );
  }
}
