import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/now.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/dates/year_month.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/info_tooltip.dart';
import '../../../core/widgets/month_switcher.dart';
import '../../../core/widgets/page_placeholder.dart';
import '../../../data/models/transaction_filter.dart';
import '../../home/widgets/section_link.dart';
import '../../shell/widgets/page_load_error.dart';
import '../../transactions/providers/transactions_drill_down.dart';
import '../models/budget_line.dart';
import '../models/budget_overview.dart';
import '../providers/budgets_providers.dart';
import '../widgets/budget_line_row.dart';
import '../widgets/budget_not_budgeted_row.dart';
import '../widgets/budget_totals_header.dart';
import '../widgets/budgets_empty_state.dart';

class BudgetsPage extends ConsumerStatefulWidget {
  const BudgetsPage({super.key});

  @override
  ConsumerState<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends ConsumerState<BudgetsPage> {
  late var _month = ref.read(currentMonthProvider);

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month.start,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
      helpText: context.l10n.transactionsPickMonth,
    );
    if (picked != null) setState(() => _month = YearMonth.of(picked));
  }

  void _edit() => context.push(Routes.editBudgets);

  void _open(BudgetLine line) {
    ref
        .read(transactionsDrillDownProvider.notifier)
        .show(
          _month,
          line.isGroup
              ? TransactionFilter(categoryGroupId: line.id)
              : TransactionFilter(categoryId: line.id),
        );
    context.go(Routes.transactions);
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(budgetOverviewProvider(_month));
    // Budgets are not per month: with none, there is no month to switch.
    final empty = overview.value?.lines.isEmpty ?? false;
    return Column(
      children: [
        if (!empty) ...[
          MonthSwitcher(
            month: _month,
            onChanged: (month) => setState(() => _month = month),
            onPick: _pickMonth,
          ),
          const Divider(),
        ],
        Expanded(
          child: switch (overview) {
            AsyncError() => PageLoadError(
              providers: [
                budgetProgressProvider,
                budgetUncoveredProvider,
                budgetOverviewProvider,
              ],
            ),
            AsyncValue(value: _?) when empty => BudgetsEmptyState(onSet: _edit),
            AsyncValue(:final value?) => _list(value),
            _ => PagePlaceholder(label: context.l10n.pageBudgets),
          },
        ),
      ],
    );
  }

  Widget _list(BudgetOverview overview) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final today = ref.watch(todayProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
      children: [
        BudgetTotalsHeader(
          overview: overview,
          daysInMonth: _month.daysInMonth,
          day: _month.contains(today) ? today.day : null,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.onSurface),
            ),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.budgetByCategory,
                        style: theme.textTheme.sectionTitle,
                      ),
                    ),
                  ),
                  InfoTooltip(
                    label: l10n.budgetBarsInfoLabel,
                    eyebrow: l10n.budgetBarsInfoEyebrow.toUpperCase(),
                    text: l10n.budgetBarsInfo,
                  ),
                ],
              ),
              SectionLink(
                l10n.budgetEdit,
                onPressed: _edit,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
        for (final line in overview.lines)
          BudgetLineRow(
            line: line,
            currency: overview.currency,
            onTap: () => _open(line),
          ),
        if (overview.notBudgeted.amount > 0 ||
            overview.notBudgeted.notIncluded.isNotEmpty)
          BudgetNotBudgetedRow(
            total: overview.notBudgeted,
            currency: overview.currency,
            onAdd: _edit,
          ),
      ],
    );
  }
}
