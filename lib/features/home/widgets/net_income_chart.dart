import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/dates/year_month.dart';
import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/money/format_money.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/chart_range.dart';
import '../../../core/widgets/chart_semantics.dart';
import '../../../core/widgets/month_chart_axes.dart';
import '../../../core/widgets/month_chart_frame.dart';
import '../models/cash_flow_month.dart';

/// Income − expenses per month around zero: positive bars `income`, negative
/// ones `expense` below the ink baseline. Negative months and the current one
/// carry their value, and so does the selected one in the readout row above;
/// "View month" drills down.
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
    final nets = [for (final m in months) m.net / microsPerUnit];
    final low = nets.fold(0.0, math.min);
    final high = nets.fold(0.0, math.max);
    // Room above and below the bars for their value labels.
    final pad = (high - low) * 0.25;
    final range = ChartRange.around(low < 0 ? low - pad : 0, high + pad);
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
      child: MonthChartFrame(
        months: [for (final m in months) m.month],
        height: 150,
        onViewMonth: onMonthTap,
        values: (i) => [AmountText(months[i].net, currency: currency)],
        chart: (selected) {
          final axes = MonthChartAxes(
            context,
            [for (final m in months) m.month],
            range,
            selected: selected,
          );
          return BarChart(
            BarChartData(
              borderData: axes.border,
              gridData: axes.grid,
              titlesData: axes.titles,
              minY: axes.range.min,
              maxY: axes.range.max,
              extraLinesData: axes.baseline,
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(
                enabled: false,
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
                        fontWeight: groupIndex == selected
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
                      if (m.net < 0 || i == months.length - 1 || i == selected)
                        0,
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
          );
        },
      ),
    );
  }
}
