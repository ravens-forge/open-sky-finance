import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../dates/year_month.dart';
import '../l10n.dart';
import '../money/format_money.dart';
import 'chart_range.dart';
import 'amount_text.dart';
import 'chart_semantics.dart';
import 'month_chart_axes.dart';
import 'month_chart_frame.dart';

class BalanceChart extends StatelessWidget {
  const BalanceChart({
    super.key,
    required this.history,
    required this.currency,
    required this.describe,
    this.onMonthTap,
  });

  /// In month order, micro-units of [currency].
  final Map<YearMonth, int> history;
  final String currency;
  final String Function(String values) describe;
  final ValueChanged<YearMonth>? onMonthTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = l10n.localeName;
    final theme = Theme.of(context);
    final months = history.keys.toList();
    // Plotted in currency units: a display value only.
    final spots = [
      for (final (i, m) in months.indexed)
        FlSpot(i.toDouble(), history[m]! / microsPerUnit),
    ];
    final monthLong = DateFormat.yMMMM(locale);
    final values = [for (final s in spots) s.y];
    final low = values.reduce(math.min);
    final high = values.reduce(math.max);
    // Room above the top point for its label.
    final range = ChartRange.around(low, high + (high - low) * 0.2);
    // The point label rounds to whole units, like "€48,230".
    final whole = NumberFormat.simpleCurrency(
      locale: locale,
      name: currency,
      decimalDigits: 0,
    );
    String money(int micros) =>
        formatMoney(micros, currency: currency, locale: locale);
    final bar = LineChartBarData(
      spots: spots,
      color: theme.colorScheme.primary,
      barWidth: 2,
      dotData: FlDotData(
        getDotPainter: (spot, _, _, index) => FlDotCirclePainter(
          radius: index == spots.length - 1 ? 5 : 3.5,
          color: index == spots.length - 1
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          strokeWidth: 2,
          strokeColor: theme.colorScheme.primary,
        ),
      ),
    );

    return ChartSemantics(
      label: describe(
        [
          for (final m in months)
            l10n.chartPointSemantic(
              monthLong.format(m.start),
              money(history[m]!),
            ),
        ].join(', '),
      ),
      months: months,
      onMonthTap: onMonthTap,
      child: MonthChartFrame(
        months: months,
        height: 160,
        onViewMonth: onMonthTap,
        values: (i) => [
          AmountText(
            history[months[i]]!,
            currency: currency,
            amountStyle: AmountStyle.balance,
          ),
        ],
        chart: (selected) {
          final axes = MonthChartAxes(
            context,
            months,
            range,
            selected: selected,
          );
          return LineChart(
            LineChartData(
              // Half a month on each side keeps the end points off the edges.
              minX: -0.5,
              maxX: months.length - 0.5,
              minY: axes.range.min,
              maxY: axes.range.max,
              borderData: axes.border,
              gridData: axes.grid,
              titlesData: axes.titles,
              showingTooltipIndicators: [
                ShowingTooltipIndicators([
                  LineBarSpot(bar, 0, spots[selected]),
                ]),
              ],
              lineTouchData: LineTouchData(
                enabled: false,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => Colors.transparent,
                  tooltipPadding: EdgeInsets.zero,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (spots) => [
                    for (final s in spots)
                      LineTooltipItem(
                        whole.format(s.y).replaceFirst('-', '−'),
                        theme.textTheme.chartValue,
                      ),
                  ],
                ),
              ),
              lineBarsData: [bar],
            ),
          );
        },
      ),
    );
  }
}
