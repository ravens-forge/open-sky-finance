import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/main_currency.dart';
import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../../../core/money/currency_converter.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_placeholder.dart';
import '../../../data/enums/category_kind.dart';
import '../../net_income/models/net_income_category_group.dart';
import '../../net_income/providers/net_income_drill_down.dart';
import '../../net_income/providers/net_income_providers.dart';
import '../../home/widgets/section_link.dart';
import '../../shell/widgets/page_load_error.dart';
import '../models/calendar_period.dart';
import 'calendar_ledger.dart';
import 'calendar_total_line.dart';

/// Income and expense groups of the period, net income and savings rate,
/// and a link to Net income for the same period.
class CalendarNetIncomeTab extends ConsumerWidget {
  const CalendarNetIncomeTab({super.key, required this.period});

  final CalendarPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final netIncome = period.netIncomePeriod;
    final summary = ref.watch(netIncomeSummaryProvider(netIncome));
    final income = ref.watch(
      netIncomeCategoriesProvider(netIncome, CategoryKind.income),
    );
    final expenses = ref.watch(
      netIncomeCategoriesProvider(netIncome, CategoryKind.expense),
    );
    final currency = ref.watch(mainCurrencyProvider).value;

    Widget amount(ConvertedTotal total, AmountStyle style) => AmountText(
      total.amount,
      currency: currency!,
      amountStyle: style,
      approximate: total.approximate,
    );
    Iterable<Widget> section(
      String title,
      ConvertedTotal total,
      List<NetIncomeCategoryGroup> groups,
    ) => [
      if (groups.isNotEmpty)
        CalendarLedgerLine(
          name: title,
          amount: amount(total, AmountStyle.signed),
          heading: true,
        ),
      for (final g in groups)
        CalendarLedgerLine(
          name: g.name ?? l10n.categoryNone,
          amount: AmountText(
            g.total.amount.abs(),
            currency: currency!,
            amountStyle: AmountStyle.balance,
            approximate: g.total.approximate,
          ),
        ),
    ];

    return switch ((summary, income, expenses, currency)) {
      (AsyncError(), _, _, _) ||
      (_, AsyncError(), _, _) ||
      (_, _, AsyncError(), _) => PageLoadError(
        providers: [
          netIncomeSummaryProvider(netIncome),
          netIncomeCategoriesProvider,
        ],
      ),
      (_, AsyncValue(value: []), AsyncValue(value: []), _) => EmptyState(
        title: l10n.calendarNoIncomeExpenses,
      ),
      (
        AsyncValue(value: final summary?),
        AsyncValue(value: final income?),
        AsyncValue(value: final expenses?),
        String(),
      ) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 6),
            ...section(l10n.netIncomeIncome, summary.income, income),
            ...section(l10n.netIncomeExpenses, summary.expense, expenses),
            CalendarTotalLine(
              label: l10n.netIncomeNet,
              amount: amount(summary.net, AmountStyle.signed),
              note: l10n.netIncomeSavingsRateLabel(
                NumberFormat.decimalPercentPattern(
                  locale: l10n.localeName,
                  decimalDigits: 1,
                ).format(summary.savingsRate),
              ),
              link: SectionLink(
                l10n.calendarOpenNetIncome,
                onPressed: () {
                  ref.read(netIncomeDrillDownProvider.notifier).show(netIncome);
                  context.go(Routes.netIncome);
                },
              ),
            ),
          ],
        ),
      _ => PagePlaceholder(label: l10n.pageCalendar, rows: 3),
    };
  }
}
