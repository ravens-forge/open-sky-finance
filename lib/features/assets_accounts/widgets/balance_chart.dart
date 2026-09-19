import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/dates/year_month.dart';
import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/money/format_money.dart';

/// Month-end balances as a line: 2 px `primary`, hollow points, the last one
/// filled; the current month label in bold ink. Read aloud as a list.
class BalanceChart extends StatelessWidget {
  const BalanceChart({
    super.key,
    required this.history,
    required this.currency,
  });

  /// In month order, micro-units of [currency].
  final Map<YearMonth, int> history;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = l10n.localeName;
    final theme = Theme.of(context);
    final finance = FinanceColors.of(context);
    final months = history.keys.toList();
    // Plotted in currency units: a display value only.
    final spots = [
      for (final (i, m) in months.indexed)
        FlSpot(i.toDouble(), history[m]! / microsPerUnit),
    ];
    final monthName = DateFormat.MMM(locale);
    final monthLong = DateFormat.yMMMM(locale);
    final compact = NumberFormat.compact(locale: locale);
    final axis = theme.textTheme.labelSmall!.copyWith(
      color: finance.muted,
      letterSpacing: 0,
    );
    String money(int micros) =>
        formatMoney(micros, currency: currency, locale: locale);

    return Semantics(
      label: l10n.assetsAccountBalanceChartSemantic(
        [
          for (final m in months)
            l10n.chartPointSemantic(
              monthLong.format(m.start),
              money(history[m]!),
            ),
        ].join(', '),
      ),
      child: ExcludeSemantics(
        child: SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (months.length - 1).toDouble(),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: theme.colorScheme.outline,
                  strokeWidth: 1,
                  dashArray: const [3, 3],
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(compact.format(value), style: axis),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final i = value.round();
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          monthName.format(months[i].start),
                          style: i == months.length - 1
                              ? axis.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                )
                              : axis,
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                  getTooltipItems: (spots) => [
                    for (final s in spots)
                      LineTooltipItem(
                        money(history[months[s.x.round()]]!),
                        TextStyle(color: theme.colorScheme.onInverseSurface),
                      ),
                  ],
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  color: theme.colorScheme.primary,
                  barWidth: 2,
                  dotData: FlDotData(
                    getDotPainter: (spot, _, _, index) => FlDotCirclePainter(
                      radius: 3.5,
                      color: index == spots.length - 1
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surface,
                      strokeWidth: 2,
                      strokeColor: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
