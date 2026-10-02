import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/main_currency.dart';
import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_placeholder.dart';
import '../../balance_sheet/providers/balance_sheet_drill_down.dart';
import '../../balance_sheet/providers/balance_sheet_providers.dart';
import '../../home/widgets/section_link.dart';
import '../../shell/widgets/page_load_error.dart';
import '../models/calendar_period.dart';
import '../providers/calendar_providers.dart';
import 'calendar_ledger.dart';
import 'calendar_total_line.dart';

/// Assets and liabilities as of the end of the period, with subtotals and
/// net worth, and a link to the Balance sheet at that date.
class CalendarBalanceSheetTab extends ConsumerWidget {
  const CalendarBalanceSheetTab({super.key, required this.period});

  final CalendarPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final asOf = ref.watch(calendarBalanceDateProvider(period));
    final sides = ref.watch(balanceSheetSidesProvider(asOf));
    final currency = ref.watch(mainCurrencyProvider).value;

    return switch ((sides, currency)) {
      (AsyncError(), _) => PageLoadError(
        providers: [balanceSheetSidesProvider(asOf)],
      ),
      (AsyncValue(value: []), _) => EmptyState(title: l10n.assetsAccountsEmpty),
      (AsyncValue(value: final sides?), final String currency) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              l10n.calendarBalanceAsOf(
                DateFormat.yMMMd(l10n.localeName).format(asOf),
              ),
              style: theme.textTheme.bodySmall!.copyWith(fontSize: 13),
            ),
          ),
          for (final side in sides) ...[
            CalendarLedgerLine(
              name: side.isLiability
                  ? l10n.assetsAccountsLiabilities
                  : l10n.assetsAccountsAssets,
              amount: AmountText(
                side.total.amount,
                currency: currency,
                amountStyle: AmountStyle.balance,
                approximate: side.total.approximate,
              ),
              heading: true,
            ),
            for (final group in side.groups)
              for (final item in group.accounts)
                CalendarLedgerLine(
                  name: item.account.name,
                  amount: AmountText(
                    item.balance,
                    currency: item.account.currency,
                    amountStyle: AmountStyle.balance,
                  ),
                ),
          ],
          CalendarTotalLine(
            label: l10n.balanceSheetNetWorth,
            amount: AmountText(
              sides.fold(0, (sum, side) => sum + side.total.amount),
              currency: currency,
              amountStyle: AmountStyle.balance,
              approximate: sides.any((side) => side.total.approximate),
            ),
            link: SectionLink(
              l10n.calendarOpenBalanceSheet,
              onPressed: () {
                ref.read(balanceSheetDrillDownProvider.notifier).show(asOf);
                context.go(Routes.balanceSheet);
              },
            ),
          ),
        ],
      ),
      _ => PagePlaceholder(label: l10n.pageCalendar, rows: 3),
    };
  }
}
