import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../app/main_currency.dart';
import '../../../app/theme.dart';
import '../../../core/l10n.dart';
import '../../../core/money/currency_converter.dart';
import '../../net_income/models/net_income_summary.dart';
import '../../net_income/providers/net_income_providers.dart';
import '../models/calendar_labels.dart';
import '../models/calendar_period.dart';
import '../models/calendar_tab.dart';
import '../providers/calendar_providers.dart';
import 'calendar_balance_sheet_tab.dart';
import 'calendar_net_income_tab.dart';
import 'calendar_period_summary.dart';
import 'calendar_reminders_tab.dart';
import 'calendar_transactions_tab.dart';

/// The selected period: its heading, the tabs, the mini summary and the open
/// tab's content.
class CalendarPeriodPanel extends HookConsumerWidget {
  const CalendarPeriodPanel({
    super.key,
    required this.period,
    required this.tab,
    required this.onTab,
  });

  final CalendarPeriod period;
  final CalendarTab tab;
  final ValueChanged<CalendarTab> onTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tabs = useTabController(
      initialLength: CalendarTab.values.length,
      initialIndex: tab.index,
    );
    // Reads the latest widget: the tab and callback change between builds.
    final latest = useRef(this)..value = this;
    useEffect(() {
      void listener() {
        if (tabs.index != latest.value.tab.index) {
          latest.value.onTab(CalendarTab.values[tabs.index]);
        }
      }

      tabs.addListener(listener);
      return () => tabs.removeListener(listener);
    }, [tabs]);
    // Each period is a new provider that starts out loading: the last
    // figures stay meanwhile, so the row does not vanish and push the tab up.
    final lastSummary = useRef<NetIncomeSummary?>(null);
    final summary = lastSummary.value =
        ref.watch(netIncomeSummaryProvider(period.netIncomePeriod)).value ??
        lastSummary.value;
    final lastNetWorth = useRef<ConvertedTotal?>(null);
    final netWorth = lastNetWorth.value =
        ref.watch(calendarNetWorthProvider(period.lastDay)).value ??
        lastNetWorth.value;
    final currency = ref.watch(mainCurrencyProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(
            calendarPeriodTitle(period, l10n),
            style: theme.textTheme.headlineSmall!.copyWith(fontSize: 22),
          ),
        ),
        const SizedBox(height: 6),
        TabBar(
          controller: tabs,
          // Scrolls when the labels do not fit (Spanish, large text).
          isScrollable: true,
          labelPadding: const EdgeInsets.symmetric(horizontal: 5),
          labelStyle: theme.textTheme.tab.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: theme.textTheme.tab.copyWith(fontSize: 13),
          dividerHeight: 1,
          tabs: [
            for (final t in CalendarTab.values)
              Tab(
                text: switch (t) {
                  CalendarTab.transactions => l10n.pageTransactions,
                  CalendarTab.reminders => l10n.pageReminders,
                  CalendarTab.netIncome => l10n.pageNetIncome,
                  CalendarTab.balanceSheet => l10n.pageBalanceSheet,
                },
              ),
          ],
        ),
        if ((summary, netWorth, currency) case (
          final summary?,
          final netWorth?,
          final currency?,
        ))
          CalendarPeriodSummary(
            income: summary.income,
            expense: summary.expense,
            netWorth: netWorth,
            currency: currency,
          ),
        switch (tab) {
          CalendarTab.transactions => CalendarTransactionsTab(period: period),
          CalendarTab.reminders => CalendarRemindersTab(period: period),
          CalendarTab.netIncome => CalendarNetIncomeTab(period: period),
          CalendarTab.balanceSheet => CalendarBalanceSheetTab(period: period),
        },
      ],
    );
  }
}
