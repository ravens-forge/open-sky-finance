import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/main_currency.dart';
import '../../../app/now.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/dates/year_month.dart';
import '../../../core/l10n.dart';
import '../../../core/money/currency_converter.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_placeholder.dart';
import '../../../core/widgets/segmented_filter.dart';
import '../../../data/enums/category_kind.dart';
import '../../../data/models/transaction_filter.dart';
import '../../transactions/providers/transactions_drill_down.dart';
import '../models/net_income_category_group.dart';
import '../models/net_income_period.dart';
import '../models/net_income_summary.dart';
import '../providers/net_income_providers.dart';
import '../widgets/net_income_category_row.dart';
import '../widgets/net_income_group_row.dart';
import '../widgets/net_income_period_switcher.dart';
import '../widgets/net_income_summary_header.dart';

class NetIncomePage extends ConsumerStatefulWidget {
  const NetIncomePage({super.key});

  @override
  ConsumerState<NetIncomePage> createState() => _NetIncomePageState();
}

class _NetIncomePageState extends ConsumerState<NetIncomePage> {
  late var _period = NetIncomePeriod.month(ref.read(currentMonthProvider));

  void _switchKind(NetIncomePeriodKind kind) {
    final anchor = _period.start;
    setState(() {
      _period = switch (kind) {
        NetIncomePeriodKind.month => NetIncomePeriod.month(
          YearMonth.of(anchor),
        ),
        NetIncomePeriodKind.quarter => NetIncomePeriod.quarter(
          anchor.year,
          NetIncomePeriod.quarterOf(YearMonth.of(anchor)),
        ),
        NetIncomePeriodKind.year => NetIncomePeriod.year(anchor.year),
        NetIncomePeriodKind.range => NetIncomePeriod.range(
          anchor,
          _period.end.subtract(const Duration(days: 1)),
        ),
      };
    });
  }

  Future<void> _pick() async {
    if (_period.kind == NetIncomePeriodKind.range) {
      final picked = await showDateRangePicker(
        context: context,
        initialDateRange: DateTimeRange(
          start: _period.start,
          end: _period.end.subtract(const Duration(days: 1)),
        ),
        firstDate: DateTime(1900),
        lastDate: ref.read(todayProvider),
      );
      if (picked != null) {
        setState(
          () => _period = NetIncomePeriod.range(picked.start, picked.end),
        );
      }
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: _period.start,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
      helpText: context.l10n.transactionsPickMonth,
    );
    if (picked != null) {
      setState(() => _period = NetIncomePeriod.month(YearMonth.of(picked)));
    }
  }

  /// Only a Month has a single [YearMonth] Transactions can jump to.
  void _open(String? categoryId) {
    if (_period.month case final month?) {
      ref
          .read(transactionsDrillDownProvider.notifier)
          .show(month, TransactionFilter(categoryId: categoryId));
      context.go(Routes.transactions);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final summary = ref.watch(netIncomeSummaryProvider(_period));
    final income = ref.watch(
      netIncomeCategoriesProvider(_period, CategoryKind.income),
    );
    final expenses = ref.watch(
      netIncomeCategoriesProvider(_period, CategoryKind.expense),
    );
    final currency = ref.watch(mainCurrencyProvider).value;

    return Column(
      children: [
        NetIncomePeriodSwitcher(
          period: _period,
          onChanged: (p) => setState(() => _period = p),
          onPick: _pick,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: SegmentedFilter<NetIncomePeriodKind>(
              options: [
                (NetIncomePeriodKind.month, l10n.netIncomePeriodMonth),
                (NetIncomePeriodKind.quarter, l10n.netIncomePeriodQuarter),
                (NetIncomePeriodKind.year, l10n.netIncomePeriodYear),
                (NetIncomePeriodKind.range, l10n.netIncomePeriodRange),
              ],
              selected: _period.kind,
              onChanged: _switchKind,
            ),
          ),
        ),
        Expanded(
          child: switch ((summary, income, expenses, currency)) {
            (AsyncError(), _, _, _) ||
            (_, AsyncError(), _, _) ||
            (
              _,
              _,
              AsyncError(),
              _,
            ) => Center(child: EmptyState(title: l10n.errorLoadFailed)),
            (
              AsyncData(value: final summary),
              AsyncData(value: final income),
              AsyncData(value: final expenses),
              final String currency,
            ) =>
              _body(summary, income, expenses, currency),
            _ => PagePlaceholder(label: l10n.pageNetIncome),
          },
        ),
      ],
    );
  }

  Widget _body(
    NetIncomeSummary summary,
    List<NetIncomeCategoryGroup> income,
    List<NetIncomeCategoryGroup> expenses,
    String currency,
  ) {
    final l10n = context.l10n;
    if (income.isEmpty && expenses.isEmpty) {
      return Center(child: EmptyState(title: l10n.netIncomeEmpty));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        NetIncomeSummaryHeader(summary: summary, currency: currency),
        _section(l10n.netIncomeIncome, income, summary.income, currency),
        _section(l10n.netIncomeExpenses, expenses, summary.expense, currency),
      ],
    );
  }

  Widget _section(
    String title,
    List<NetIncomeCategoryGroup> groups,
    ConvertedTotal total,
    String currency,
  ) {
    if (groups.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final tappable = _period.kind == NetIncomePeriodKind.month;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 22),
          child: Container(
            padding: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.onSurface),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: theme.textTheme.sectionTitle),
                ),
                AmountText(
                  total.amount,
                  currency: currency,
                  amountStyle: AmountStyle.signed,
                  approximate: total.approximate,
                  style: theme.textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        for (final group in groups) ...[
          NetIncomeGroupRow(group: group, currency: currency),
          for (final category in group.categories)
            NetIncomeCategoryRow(
              category: category,
              currency: currency,
              onTap: tappable ? () => _open(category.categoryId) : null,
            ),
        ],
      ],
    );
  }
}
