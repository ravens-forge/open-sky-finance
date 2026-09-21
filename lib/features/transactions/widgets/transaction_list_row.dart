import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/category_icons.dart';
import '../../../core/widgets/transaction_row.dart';
import '../../../data/enums/transaction_type.dart';
import '../../../data/models/assets_account.dart';
import '../../../data/models/category.dart';
import '../../../data/models/label.dart';
import '../../../data/models/transaction.dart';

/// A transaction in the ledger: category icon, title, category and assets
/// account (`From -> To` for transfers), label chips and the signed amount.
/// Scheduled rows lead with their date, since they sit outside the day groups.
class TransactionListRow extends StatelessWidget {
  const TransactionListRow({
    super.key,
    required this.transaction,
    required this.categories,
    required this.assetsAccounts,
    required this.labels,
    required this.scheduled,
    required this.onTap,
  });

  final Transaction transaction;
  final Map<String, Category> categories;
  final Map<String, AssetsAccount> assetsAccounts;
  final List<Label> labels;
  final bool scheduled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final finance = FinanceColors.of(context);
    final t = transaction;
    final category = categories[t.categoryId];
    final account = assetsAccounts[t.assetsAccountId]?.name ?? '';
    final untitled = t.title.isEmpty;

    final (
      IconData icon,
      Color color,
      String title,
      String subtitle,
    ) = switch (t.type) {
      TransactionType.transfer => (
        Icons.swap_horiz,
        finance.transfer,
        untitled ? t.type.label(l10n) : t.title,
        l10n.transferFromTo(
          account,
          assetsAccounts[t.transfer!.assetsAccountId]?.name ?? '',
        ),
      ),
      TransactionType.openingBalance => (
        Icons.flag_outlined,
        Theme.of(context).colorScheme.primary,
        untitled ? t.type.label(l10n) : t.title,
        account,
      ),
      _ => (
        category == null ? fallbackCategoryIcon : categoryIcon(category.icon),
        Color(category?.color ?? finance.muted.toARGB32()),
        untitled ? category?.name ?? l10n.categoryNone : t.title,
        l10n.transactionSubtitle(category?.name ?? l10n.categoryNone, account),
      ),
    };

    return TransactionRow(
      icon: icon,
      iconColor: color,
      title: title,
      subtitle: scheduled
          ? l10n.transactionSubtitleDated(
              DateFormat.MMMd(l10n.localeName).format(t.occurredAt),
              subtitle,
            )
          : subtitle,
      labels: [for (final label in labels) label.name],
      scheduled: scheduled,
      onTap: onTap,
      amount: AmountText(
        t.amount.micros,
        currency: t.amount.currency,
        amountStyle: switch (t.type) {
          TransactionType.transfer => AmountStyle.transfer,
          TransactionType.openingBalance => AmountStyle.balance,
          _ => AmountStyle.signed,
        },
      ),
    );
  }
}
