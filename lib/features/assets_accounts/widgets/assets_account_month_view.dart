import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/routes.dart';
import '../../../core/dates/wall_clock.dart';
import '../../../core/dates/year_month.dart';
import '../../../core/l10n.dart';
import '../../../core/money/format_money.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/day_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/month_switcher.dart';
import '../../../data/models/assets_account.dart';
import '../providers/assets_account_detail_providers.dart';
import '../providers/assets_accounts_providers.dart';
import 'assets_account_transaction_row.dart';

/// The month picker, money in and out, and the month's transactions by day
/// with the balance at the end of each day.
class AssetsAccountMonthView extends ConsumerWidget {
  const AssetsAccountMonthView({
    super.key,
    required this.account,
    required this.month,
    required this.onMonthChanged,
  });

  final AssetsAccount account;
  final YearMonth month;
  final ValueChanged<YearMonth> onMonthChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final data = ref.watch(assetsAccountMonthProvider(account.id, month)).value;
    final categories = ref.watch(categoriesByIdProvider).value ?? const {};
    final names = {
      for (final a
          in ref.watch(assetsAccountsProvider).value ?? <AssetsAccount>[])
        a.id: a.name,
    };
    final tomorrow = startOfTomorrow();
    final day = DateFormat.MMMMEEEEd(l10n.localeName);

    Widget total(String label, int micros) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.bodySmall),
          AmountText(
            micros,
            currency: account.currency,
            style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonthSwitcher(month: month, onChanged: onMonthChanged),
        if (data != null) ...[
          Row(
            children: [
              total(l10n.assetsAccountMoneyIn, data.moneyIn),
              total(l10n.assetsAccountMoneyOut, data.moneyOut),
            ],
          ),
          if (data.days.isEmpty)
            EmptyState(title: l10n.assetsAccountNoTransactions),
          for (final d in data.days) ...[
            DayHeader(
              title: capitalizeFirst(day.format(d.date)),
              trailing: Text(
                l10n.assetsAccountDayBalance(
                  formatMoney(
                    d.balance,
                    currency: account.currency,
                    locale: l10n.localeName,
                  ),
                ),
              ),
            ),
            for (final t in d.transactions)
              AssetsAccountTransactionRow(
                transaction: t,
                assetsAccountId: account.id,
                currency: account.currency,
                categories: categories,
                assetsAccountNames: names,
                scheduled: !t.occurredAt.isBefore(tomorrow),
                onTap: () => context.push(Routes.transaction(t.id)),
              ),
          ],
        ],
      ],
    );
  }
}
