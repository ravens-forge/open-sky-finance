import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/dates/year_month.dart';
import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/money/format_money.dart';
import '../../../core/widgets/chart_semantics.dart';
import '../../../core/widgets/month_chart_axes.dart';
import '../models/cash_flow_month.dart';

/// Income − expenses per month around zero: positive bars `income`, negative
/// ones `expense` below the ink baseline. Negative months and the current one
/// carry their value. Tapping a month drills down.
class NetIncomeChart extends StatelessWidget {
  const NetIncomeChart({
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
    final axes = MonthChartAxes(context, [for (final m in months) m.month]);
    final monthLong = DateFormat.yMMMM(locale);
    final whole = NumberFormat.decimalPattern(locale)
      ..maximumFractionDigits = 0;
    final width = months.length > 6 ? 11.0 : 22.0;
    Color colorOf(int net) => net < 0 ? finance.expense : finance.income;

    return ChartSemantics(
      label: l10n.homeNetIncomeSemantic(
        [
          for (final m in months)
            l10n.chartPointSemantic(
              monthLong.format(m.month.start),
              formatMoney(m.net, currency: currency, locale: locale),
            ),
        ].join(', '),
      ),
      months: [for (final m in months) m.month],
      onMonthTap: onMonthTap,
      child: SizedBox(
        height: 150,
        child: BarChart(
          BarChartData(
            borderData: axes.border,
            gridData: axes.grid,
            titlesData: axes.titles,
            extraLinesData: axes.baseline,
            alignment: BarChartAlignment.spaceAround,
            barTouchData: BarTouchData(
              handleBuiltInTouches: false,
              touchCallback: (event, response) {
                final spot = response?.spot;
                if (event is FlTapUpEvent && spot != null) {
                  onMonthTap(months[spot.touchedBarGroupIndex].month);
                }
              },
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.transparent,
                tooltipPadding: EdgeInsets.zero,
                tooltipMargin: 4,
                fitInsideVertically: true,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final net = months[groupIndex].net;
                  final value = whole.format((net / microsPerUnit).abs());
                  return BarTooltipItem(
                    net < 0 ? '−$value' : '+$value',
                    theme.textTheme.labelSmall!.copyWith(
                      color: colorOf(net),
                      fontWeight: groupIndex == months.length - 1
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  );
                },
              ),
            ),
            barGroups: [
              for (final (i, m) in months.indexed)
                BarChartGroupData(
                  x: i,
                  showingTooltipIndicators: [
                    if (m.net < 0 || i == months.length - 1) 0,
                  ],
                  barRods: [
                    BarChartRodData(
                      // Plotted in currency units: a display value only.
                      toY: m.net / microsPerUnit,
                      color: colorOf(m.net),
                      width: width,
                      borderRadius: BorderRadius.zero,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
