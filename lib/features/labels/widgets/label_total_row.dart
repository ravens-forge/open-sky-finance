import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../app/theme.dart';
import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/money/currency_converter.dart';
import '../../../core/money/format_money.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/category_avatar.dart';
import '../../../core/widgets/choice_sheet.dart';
import '../../../data/models/label_total.dart';

class LabelTotalRow extends StatelessWidget {
  const LabelTotalRow({
    super.key,
    required this.total,
    required this.converter,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final LabelTotal total;
  final CurrencyConverter converter;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = FinanceColors.of(context).muted;
    final used = total.count > 0;
    final converted = converter.convert(total.total);
    return Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: l10n.actionRename): onRename,
        CustomSemanticsAction(label: l10n.actionDelete): onDelete,
      },
      child: InkWell(
        onTap: onTap,
        onLongPress: () async {
          final action = await showChoiceSheet<VoidCallback?>(
            context,
            title: total.label.name,
            options: [
              (onRename, l10n.actionRename),
              (onDelete, l10n.actionDelete),
            ],
            selected: null,
          );
          action?.call();
        },
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(total.label.name, style: theme.textTheme.rowTitle),
                    Text(
                      l10n.labelsCount(total.count),
                      style: theme.textTheme.rowSubtitle.copyWith(color: muted),
                    ),
                    if (converted.notIncluded.isNotEmpty)
                      Text(
                        l10n.assetsAccountsNotIncluded(
                          [
                            for (final MapEntry(key: currency, value: micros)
                                in converted.notIncluded.entries)
                              formatMoney(
                                micros,
                                currency: currency,
                                locale: l10n.localeName,
                              ),
                          ].join(', '),
                        ),
                        style: theme.textTheme.rowSubtitle,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AmountText(
                converted.amount,
                currency: converter.mainCurrency,
                approximate: converted.approximate,
                style: theme.textTheme.rowAmount,
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
