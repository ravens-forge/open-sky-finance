import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/main_currency.dart';
import '../../../app/routes.dart';
import '../../../core/dates/wall_clock.dart';
import '../../../core/l10n.dart';
import '../../../core/money/format_money.dart';
import '../models/home_section_place.dart';
import '../providers/home_providers.dart';
import 'budget_pie_chart.dart';
import 'chart_empty_note.dart';
import 'home_section_frame.dart';

class BudgetSummarySection extends ConsumerWidget {
  const BudgetSummarySection({super.key, required this.place});

  final HomeSectionPlace place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = l10n.localeName;
    final summary = ref.watch(homeBudgetSummaryProvider).value;
    final currency = ref.watch(mainCurrencyProvider).value;
    void openBudgets() => context.go(Routes.budgets);
    return HomeSectionFrame(
      title: l10n.homeSectionBudgetSummary,
      place: place,
      caption: Text(
        capitalizeFirst(DateFormat.MMMM(locale).format(DateTime.now())),
      ),
      child: switch ((summary, currency)) {
        (final summary?, final currency?) when summary.budgeted > 0 => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            BudgetPieChart(
              summary: summary,
              currency: currency,
              onTap: openBudgets,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.homeBudgetSpent(
                      formatMoney(
                        summary.spent,
                        currency: currency,
                        locale: locale,
                      ),
                      formatMoney(
                        summary.budgeted,
                        currency: currency,
                        locale: locale,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: openBudgets,
                  child: Text(l10n.homeBudgetDetails),
                ),
              ],
            ),
          ],
        ),
        (_?, _?) => ChartEmptyNote(
          l10n.homeBudgetEmpty,
          action: OutlinedButton(
            onPressed: openBudgets,
            child: Text(l10n.homeBudgetSet),
          ),
        ),
        _ => const SizedBox(height: 140),
      },
    );
  }
}
