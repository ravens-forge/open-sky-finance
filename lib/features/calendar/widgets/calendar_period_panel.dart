import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/main_currency.dart';
import '../../../app/theme.dart';
import '../../../core/l10n.dart';
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
class CalendarPeriodPanel extends ConsumerStatefulWidget {
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
  ConsumerState<CalendarPeriodPanel> createState() =>
      _CalendarPeriodPanelState();
}

class _CalendarPeriodPanelState extends ConsumerState<CalendarPeriodPanel>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(
    length: CalendarTab.values.length,
    initialIndex: widget.tab.index,
    vsync: this,
  )..addListener(_onTab);

  void _onTab() {
    if (_tabs.index != widget.tab.index) {
      widget.onTab(CalendarTab.values[_tabs.index]);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final period = widget.period;
    final summary = ref
        .watch(netIncomeSummaryProvider(period.netIncomePeriod))
        .value;
    final netWorth = ref
        .watch(
          calendarNetWorthProvider(
            ref.watch(calendarBalanceDateProvider(period)),
          ),
        )
        .value;
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
          controller: _tabs,
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
            for (final tab in CalendarTab.values)
              Tab(
                text: switch (tab) {
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
        switch (widget.tab) {
          CalendarTab.transactions => CalendarTransactionsTab(period: period),
          CalendarTab.reminders => CalendarRemindersTab(period: period),
          CalendarTab.netIncome => CalendarNetIncomeTab(period: period),
          CalendarTab.balanceSheet => CalendarBalanceSheetTab(period: period),
        },
      ],
    );
  }
}
