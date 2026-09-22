import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../dates/year_month.dart';
import '../l10n.dart';
import '../money/format_money.dart';
import 'chart_range.dart';
import 'chart_semantics.dart';
import 'month_chart_axes.dart';

class BalanceChart extends StatefulWidget {
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
  State<BalanceChart> createState() => _BalanceChartState();
}

class _BalanceChartState extends State<BalanceChart> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = l10n.localeName;
    final theme = Theme.of(context);
    final months = widget.history.keys.toList();
    // Plotted in currency units: a display value only.
    final spots = [
      for (final (i, m) in months.indexed)
        FlSpot(i.toDouble(), widget.history[m]! / microsPerUnit),
    ];
    final monthLong = DateFormat.yMMMM(locale);
    final values = [for (final s in spots) s.y];
    final low = values.reduce(math.min);
    final high = values.reduce(math.max);
    final axes = MonthChartAxes(
      context,
      months,
      // Room above the top point for its label.
      ChartRange.around(low, high + (high - low) * 0.2),
    );
    // The point label rounds to whole units, like "€48,230".
    final whole = NumberFormat.simpleCurrency(
      locale: locale,
      name: widget.currency,
      decimalDigits: 0,
    );
    String money(int micros) =>
        formatMoney(micros, currency: widget.currency, locale: locale);
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
    final labelled = (_touched ?? spots.length - 1).clamp(0, spots.length - 1);

    return ChartSemantics(
      label: widget.describe(
        [
          for (final m in months)
            l10n.chartPointSemantic(
              monthLong.format(m.start),
              money(widget.history[m]!),
            ),
        ].join(', '),
      ),
      months: months,
      onMonthTap: widget.onMonthTap,
      child: SizedBox(
        height: 160,
        child: LineChart(
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
              if (spots.isNotEmpty)
                ShowingTooltipIndicators([
                  LineBarSpot(bar, 0, spots[labelled]),
                ]),
            ],
            lineTouchData: LineTouchData(
              handleBuiltInTouches: false,
              touchCallback: (event, response) {
                final spot = response?.lineBarSpots?.firstOrNull;
                if (!event.isInterestedForInteractions) {
                  setState(() => _touched = null);
                } else if (spot != null) {
                  setState(() => _touched = spot.x.round());
                }
                if (event is FlTapUpEvent && spot != null) {
                  widget.onMonthTap?.call(months[spot.x.round()]);
                }
              },
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
        ),
      ),
    );
  }
}
