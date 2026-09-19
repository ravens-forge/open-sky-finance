import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../app/theme.dart';
import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/money/format_money.dart';
import '../../../core/widgets/amount_text.dart';
import '../models/assets_account_with_balance.dart';
import '../models/credit_usage.dart';
import 'assets_account_avatar.dart';
import 'credit_usage_bar.dart';

/// Drag handle, icon, name and type, balance and favorite star; credit cards
/// with a limit add their usage below. Must sit in a `ReorderableListView`.
class AssetsAccountRow extends StatelessWidget {
  const AssetsAccountRow({
    super.key,
    required this.item,
    required this.index,
    required this.mainCurrency,
    required this.onTap,
    required this.onFavorite,
    this.onMoveUp,
    this.onMoveDown,
  });

  final AssetsAccountWithBalance item;

  /// Position in the reorderable list.
  final int index;

  /// Other currencies are named under the name.
  final String mainCurrency;
  final VoidCallback onTap;
  final ValueChanged<bool> onFavorite;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final finance = FinanceColors.of(context);
    final AssetsAccountWithBalance(:account, :balance) = item;
    final usage = CreditUsage.of(account, balance);
    String money(int micros) => formatMoney(
      micros,
      currency: account.currency,
      locale: l10n.localeName,
    );

    return Material(
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Semantics(
                    label: l10n.assetsAccountMove(account.name),
                    customSemanticsActions: {
                      CustomSemanticsAction(label: l10n.actionMoveUp):
                          ?onMoveUp,
                      CustomSemanticsAction(label: l10n.actionMoveDown):
                          ?onMoveDown,
                    },
                    child: ReorderableDragStartListener(
                      index: index,
                      child: SizedBox.square(
                        dimension: 44,
                        child: Icon(
                          Icons.drag_indicator,
                          size: 20,
                          color: finance.disabled,
                        ),
                      ),
                    ),
                  ),
                  AssetsAccountAvatar(account.type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(account.name, style: theme.textTheme.rowTitle),
                        Text(
                          [
                            account.type.label(l10n),
                            if (account.currency != mainCurrency)
                              account.currency,
                            if (account.isHidden) l10n.assetsAccountHidden,
                            if (account.excludeFromNetWorth)
                              l10n.assetsAccountExcluded,
                          ].join(' · '),
                          style: theme.textTheme.rowSubtitle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AmountText(
                    balance,
                    currency: account.currency,
                    amountStyle: AmountStyle.balance,
                    style: theme.textTheme.rowAmount,
                  ),
                  IconButton(
                    isSelected: account.isFavorite,
                    tooltip: l10n.assetsAccountFavorite(account.name),
                    onPressed: () => onFavorite(!account.isFavorite),
                    icon: Icon(Icons.star_border, color: finance.disabled),
                    selectedIcon: Icon(
                      Icons.star,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              if (usage != null)
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(92, 0, 48, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 4,
                    children: [
                      CreditUsageBar(usage),
                      Text(
                        l10n.assetsAccountCreditAvailableOf(
                          money(usage.available),
                          money(usage.limit),
                        ),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
