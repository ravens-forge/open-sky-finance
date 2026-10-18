import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../app/theme.dart';
import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/money/currency_order.dart';
import '../../../core/money/format_money.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/category_avatar.dart';
import '../../../core/widgets/action_sheet.dart';
import '../../../data/models/label_total.dart';
import '../../../core/widgets/trailing_amount.dart';

class LabelTotalRow extends StatelessWidget {
  const LabelTotalRow({
    super.key,
    required this.total,
    required this.defaultCurrency,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final LabelTotal total;
  final String defaultCurrency;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = FinanceColors.of(context).muted;
    final used = total.count > 0;
    // One amount fits: the first currency's, the others are a tap away.
    final amounts = totalsInOrder(total.total, defaultCurrency);
    return Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: l10n.actionRename): onRename,
        CustomSemanticsAction(label: l10n.actionDelete): onDelete,
      },
      child: InkWell(
        onTap: onTap,
        onLongPress: () => showActionSheet(
          context,
          title: total.label.name,
          actions: [
            SheetAction(
              Icons.drive_file_rename_outline,
              l10n.actionRename,
              onRename,
            ),
            SheetAction(Icons.delete_outline, l10n.actionDelete, onDelete),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              CategoryAvatar(
                icon: Icons.sell_outlined,
                color: used ? theme.colorScheme.primary : muted,
                // Empty labels keep the neutral container.
                background: used ? theme.colorScheme.primaryContainer : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TrailingAmount(
                  text: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(total.label.name, style: theme.textTheme.rowTitle),
                      Text(
                        l10n.labelsCount(total.count),
                        style: theme.textTheme.rowSubtitle.copyWith(
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                  amount: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AmountText(
                        amounts.first.value,
                        currency: amounts.first.key,
                        style: theme.textTheme.rowAmount,
                        code: sharedSymbols(
                          amounts.map((a) => a.key),
                          l10n.localeName,
                        ).contains(amounts.first.key),
                      ),
                      if (amounts.length > 1)
                        Text(
                          l10n.labelsMoreCurrencies(amounts.length - 1),
                          style: theme.textTheme.rowSubtitle.copyWith(
                            color: muted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}
