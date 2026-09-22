import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/dates/year_month.dart';
import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/money/format_money.dart';
import '../../../core/widgets/chart_range.dart';
import '../../../core/widgets/chart_semantics.dart';
import '../../../core/widgets/month_chart_axes.dart';
import '../models/cash_flow_month.dart';
import 'chart_legend_item.dart';

/// Income bar (`income`) then expense bar (`expense`) per month, square ends,
/// legend above. Tapping a month drills down.
class CashFlowChart extends StatelessWidget {
  const CashFlowChart({
    super.key,
    required this.months,
    required this.currency,
    required this.onMonthTap,
  });

  final List<CashFlowMonth> months;
  final String currency;
  final ValueChanged<YearMonth> onMonthTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = l10n.localeName;
    final theme = Theme.of(context);
    final finance = FinanceColors.of(context);
    final top = months.fold(
      0.0,
      (top, m) => math.max(top, math.max(m.income, -m.expense) / microsPerUnit),
    );
    final axes = MonthChartAxes(context, [
      for (final m in months) m.month,
    ], ChartRange.around(0, top));
    final monthLong = DateFormat.yMMMM(locale);
    final width = months.length > 6 ? 6.0 : 13.0;
    String money(int micros) =>
        formatMoney(micros, currency: currency, locale: locale);
    BarChartRodData rod(int micros, Color color) => BarChartRodData(
      // Plotted in currency units: a display value only.
      toY: micros / microsPerUnit,
      color: color,
      width: width,
      borderRadius: BorderRadius.zero,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        ExcludeSemantics(
          child: Wrap(
            spacing: 16,
            children: [
              ChartLegendItem(finance.income, l10n.transactionsIncome),
              ChartLegendItem(finance.expense, l10n.transactionsExpenses),
            ],
          ),
        ),
        ChartSemantics(
          label: l10n.homeCashFlowSemantic(
            [
              for (final m in months)
                l10n.homeCashFlowPointSemantic(
                  monthLong.format(m.month.start),
                  money(m.income),
                  money(-m.expense),
                ),
            ].join(', '),
          ),
          months: [for (final m in months) m.month],
          onMonthTap: onMonthTap,
          child: SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                borderData: axes.border,
                gridData: axes.grid,
                titlesData: axes.titles,
                minY: axes.range.min,
                maxY: axes.range.max,
                extraLinesData: axes.baseline,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  touchCallback: (event, response) {
                    final spot = response?.spot;
                    if (event is FlTapUpEvent && spot != null) {
                      onMonthTap(months[spot.touchedBarGroupIndex].month);
                    }
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final m = months[groupIndex];
                      return BarTooltipItem(
                        rodIndex == 0
                            ? '+${money(m.income)}'
                            : '−${money(-m.expense)}',
                        TextStyle(color: theme.colorScheme.onInverseSurface),
                      );
                    },
                  ),
                ),
                barGroups: [
                  for (final (i, m) in months.indexed)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 2,
                      barRods: [
                        rod(m.income, finance.income),
                        rod(-m.expense, finance.expense),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
