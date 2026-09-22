import 'package:flutter/material.dart';

import '../../../core/l10n.dart';
import '../../../core/money/format_money.dart';
import '../../../core/widgets/leader_row.dart';
import '../models/net_income_category_group.dart';

class NetIncomeCategoryRow extends StatelessWidget {
  const NetIncomeCategoryRow({
    super.key,
    required this.category,
    required this.currency,
    this.onTap,
  });

  final NetIncomeCategory category;
  final String currency;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16),
      child: LeaderRow(
        name: category.name ?? l10n.categoryNone,
        amount: Text(
          formatMoney(
            category.total.amount.abs(),
            currency: currency,
            locale: l10n.localeName,
          ),
          style: theme.textTheme.bodyMedium!.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: muted,
          ),
        ),
        onTap: category.categoryId == null ? null : onTap,
      ),
    );
  }
}
