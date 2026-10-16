import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
import '../providers/net_income_drill_down.dart';
import '../providers/net_income_providers.dart';
import '../widgets/net_income_category_row.dart';
import '../widgets/net_income_group_row.dart';
import '../widgets/net_income_period_switcher.dart';
import '../widgets/net_income_summary_header.dart';
import '../../shell/widgets/page_load_error.dart';

class NetIncomePage extends HookConsumerWidget {
  const NetIncomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Opens on what another page drilled down to, if anything.
    final drilled = useMemoized(() => ref.read(netIncomeDrillDownProvider));
    final state = useState(
      useMemoized(
        () => drilled ?? NetIncomePeriod.month(ref.read(currentMonthProvider)),
      ),
    );
    final period = state.value;

    // Clears the drill-down once shown, so it is not shown again.
    void clearDrillDown() =>
        Future.microtask(ref.read(netIncomeDrillDownProvider.notifier).clear);
    useEffect(() {
      if (drilled != null) clearDrillDown();
      return null;
    }, const []);
    ref.listen(netIncomeDrillDownProvider, (_, next) {
      if (next == null) return;
      state.value = next;
      clearDrillDown();
    });

    void switchKind(NetIncomePeriodKind kind) {
      final anchor = period.start;
      state.value = switch (kind) {
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
          period.end.subtract(const Duration(days: 1)),
        ),
      };
    }

    Future<void> pick() async {
      if (period.kind == NetIncomePeriodKind.range) {
        final picked = await showDateRangePicker(
          context: context,
          initialDateRange: DateTimeRange(
            start: period.start,
            end: period.end.subtract(const Duration(days: 1)),
          ),
          firstDate: DateTime(1900),
          lastDate: ref.read(todayProvider),
        );
        if (picked != null) {
          state.value = NetIncomePeriod.range(picked.start, picked.end);
        }
        return;
      }
      final picked = await showDatePicker(
        context: context,
        initialDate: period.start,
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
        initialDatePickerMode: DatePickerMode.year,
        helpText: l10n.transactionsPickMonth,
      );
      if (picked != null) {
        state.value = NetIncomePeriod.month(YearMonth.of(picked));
      }
    }

    // Only a Month has a single [YearMonth] Transactions can jump to.
    void open(String? categoryId) {
      if (period.month case final month?) {
        ref
            .read(transactionsDrillDownProvider.notifier)
            .show(month, TransactionFilter(categoryId: categoryId));
        context.go(Routes.transactions);
      }
    }

    final summary = ref.watch(netIncomeSummaryProvider(period));
    final income = ref.watch(
      netIncomeCategoriesProvider(period, CategoryKind.income),
    );
    final expenses = ref.watch(
      netIncomeCategoriesProvider(period, CategoryKind.expense),
    );
    final currency = ref.watch(mainCurrencyProvider).value;

    return Column(
      children: [
        NetIncomePeriodSwitcher(
          period: period,
          onChanged: (p) => state.value = p,
          onPick: pick,
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
              selected: period.kind,
              onChanged: switchKind,
            ),
          ),
        ),
        Expanded(
          child: switch ((summary, income, expenses, currency)) {
            (AsyncError(), _, _, _) ||
            (_, AsyncError(), _, _) ||
            (_, _, AsyncError(), _) => PageLoadError(
              providers: [
                netIncomeSummaryProvider(period),
                netIncomeCategoriesProvider,
              ],
            ),
            (
              AsyncValue(value: final summary?),
              AsyncValue(value: final income?),
              AsyncValue(value: final expenses?),
              final String currency,
            ) =>
              _NetIncomeBody(
                summary: summary,
                income: income,
                expenses: expenses,
                currency: currency,
                onOpen: period.kind == NetIncomePeriodKind.month ? open : null,
              ),
            _ => PagePlaceholder(label: l10n.pageNetIncome),
          },
        ),
      ],
    );
  }
}

class _NetIncomeBody extends StatelessWidget {
  const _NetIncomeBody({
    required this.summary,
    required this.income,
    required this.expenses,
    required this.currency,
    required this.onOpen,
  });

  final NetIncomeSummary summary;
  final List<NetIncomeCategoryGroup> income;
  final List<NetIncomeCategoryGroup> expenses;
  final String currency;

  /// Opens a category's transactions; `null` when the period is not a month.
  final ValueChanged<String?>? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (income.isEmpty && expenses.isEmpty) {
      return Center(child: EmptyState(title: l10n.netIncomeEmpty));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        NetIncomeSummaryHeader(summary: summary, currency: currency),
        _section(context, l10n.netIncomeIncome, income, summary.income),
        _section(context, l10n.netIncomeExpenses, expenses, summary.expense),
      ],
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    List<NetIncomeCategoryGroup> groups,
    ConvertedTotal total,
  ) {
    if (groups.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final onOpen = this.onOpen;

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
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
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
              onTap: onOpen == null ? null : () => onOpen(category.categoryId),
            ),
        ],
      ],
    );
  }
}
