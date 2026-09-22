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
import 'section_link.dart';

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
                  child: _SpentLine(
                    spent: formatMoney(
                      summary.spent,
                      currency: currency,
                      locale: locale,
                    ),
                    budgeted: formatMoney(
                      summary.budgeted,
                      currency: currency,
                      locale: locale,
                    ),
                  ),
                ),
                SectionLink(l10n.homeBudgetDetails, onPressed: openBudgets),
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

/// "Spent €1,872.20 of €2,070.00", the spent amount in bold.
class _SpentLine extends StatelessWidget {
  const _SpentLine({required this.spent, required this.budgeted});

  final String spent;
  final String budgeted;

  @override
  Widget build(BuildContext context) {
    final text = context.l10n.homeBudgetSpent(spent, budgeted);
    final at = text.indexOf(spent);
    return Text.rich(
      TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: [
          TextSpan(text: text.substring(0, at)),
          TextSpan(
            text: spent,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: text.substring(at + spent.length)),
        ],
      ),
    );
  }
}
