import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/money/format_money.dart';
import '../../../core/widgets/budget_bar.dart';
import '../../../core/widgets/category_avatar.dart';
import '../../../core/widgets/category_icons.dart';
import '../../../core/widgets/trailing_amount.dart';
import '../../../data/enums/category_kind.dart';
import '../models/budget_line.dart';

class BudgetLineRow extends StatelessWidget {
  const BudgetLineRow({
    super.key,
    required this.line,
    required this.currency,
    required this.onTap,
  });

  final BudgetLine line;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final finance = FinanceColors.of(context);
    final locale = l10n.localeName;
    String money(int micros) =>
        formatMoney(micros, currency: currency, locale: locale);

    final (status, statusColor) = switch (line.state) {
      BudgetState.under => (l10n.budgetLeft(money(line.left)), finance.muted),
      BudgetState.near => (l10n.budgetLeft(money(line.left)), finance.warning),
      BudgetState.usedUp => (l10n.budgetUsedUp, theme.colorScheme.onSurface),
      BudgetState.over => (l10n.budgetOver(money(-line.left)), finance.expense),
    };
    final spent = money(line.spent);
    // A group has no icon of its own: the arrow of its type, in its colour.
    final expense = CategoryKind.expense.color(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Row(
              children: [
                line.isGroup
                    ? CategoryAvatar(
                        icon: CategoryKind.expense.icon,
                        color: expense,
                        background: expense.withValues(alpha: 0.14),
                        size: 36,
                      )
                    : CategoryAvatar(
                        icon: categoryIcon(line.icon ?? ''),
                        color: Color(line.color ?? 0),
                        size: 36,
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: TrailingAmount(
                    text: Text(line.name, style: theme.textTheme.rowTitle),
                    amount: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: line.approximate
                                ? l10n.amountApproximate(spent)
                                : spent,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: ' / ${money(line.budget)}',
                            style: TextStyle(color: finance.muted),
                          ),
                        ],
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
            BudgetBar(spentMicros: line.spent, budgetMicros: line.budget),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                  NumberFormat.percentPattern(locale)
                      .format(line.percent / 100),
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  status,
                  style: theme.textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
