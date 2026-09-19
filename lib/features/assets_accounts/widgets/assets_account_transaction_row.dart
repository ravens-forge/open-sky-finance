import 'package:flutter/material.dart';

import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/category_icons.dart';
import '../../../core/widgets/transaction_row.dart';
import '../../../data/enums/transaction_type.dart';
import '../../../data/models/category.dart';
import '../../../data/models/transaction.dart';
import '../models/assets_account_month.dart';

/// A transaction as seen from one assets account: its effect on it, the
/// category (or `From → To` for transfers).
class AssetsAccountTransactionRow extends StatelessWidget {
  const AssetsAccountTransactionRow({
    super.key,
    required this.transaction,
    required this.assetsAccountId,
    required this.currency,
    required this.categories,
    required this.assetsAccountNames,
    required this.scheduled,
    required this.onTap,
  });

  final Transaction transaction;
  final String assetsAccountId;

  /// Of [assetsAccountId].
  final String currency;
  final Map<String, Category> categories;
  final Map<String, String> assetsAccountNames;
  final bool scheduled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final finance = FinanceColors.of(context);
    final t = transaction;
    final category = categories[t.categoryId];
    final group = categories[category?.parentId] ?? category;
    final effect = effectOn(t, assetsAccountId);

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
          assetsAccountNames[t.assetsAccountId] ?? '',
          assetsAccountNames[t.transfer!.assetsAccountId] ?? '',
        ),
      ),
      TransactionType.openingBalance => (
        Icons.flag_outlined,
        Theme.of(context).colorScheme.primary,
        untitled ? t.type.label(l10n) : t.title,
        assetsAccountNames[t.assetsAccountId] ?? '',
      ),
      _ => (
        category == null ? fallbackCategoryIcon : categoryIcon(category.icon),
        Color(category?.color ?? group?.color ?? finance.muted.toARGB32()),
        untitled ? category?.name ?? l10n.categoryNone : t.title,
        untitled ? t.type.label(l10n) : category?.name ?? l10n.categoryNone,
      ),
    };

    return TransactionRow(
      icon: icon,
      iconColor: color,
      title: title,
      subtitle: subtitle,
      scheduled: scheduled,
      onTap: onTap,
      amount: AmountText(
        t.type == TransactionType.transfer ? effect.abs() : effect,
        currency: currency,
        amountStyle: switch (t.type) {
          TransactionType.transfer => AmountStyle.transfer,
          TransactionType.openingBalance => AmountStyle.balance,
          _ => AmountStyle.signed,
        },
      ),
    );
  }
}
