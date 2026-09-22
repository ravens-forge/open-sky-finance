import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../dates/year_month.dart';
import '../finance_colors.dart';
import '../l10n.dart';
import 'chart_range.dart';

/// Grid, borders and axis titles shared by the monthly charts: dashed
/// `outline` grid lines on the round steps of [range], no border, compact
/// values on the left and month names below, the current month in bold ink.
/// Twelve months label every other one.
class MonthChartAxes {
  MonthChartAxes(BuildContext context, this.months, this.range)
    : _theme = Theme.of(context),
      _locale = context.l10n.localeName,
      _muted = FinanceColors.of(context).muted;

  final List<YearMonth> months;
  final ChartRange range;
  final ThemeData _theme;
  final String _locale;
  final Color _muted;

  TextStyle get _axis =>
      _theme.textTheme.labelSmall!.copyWith(color: _muted, letterSpacing: 0);

  FlBorderData get border => FlBorderData(show: false);

  FlGridData get grid => FlGridData(
    drawVerticalLine: false,
    horizontalInterval: range.step,
    getDrawingHorizontalLine: (_) => FlLine(
      color: _theme.colorScheme.outlineVariant,
      strokeWidth: 1,
      dashArray: const [3, 3],
    ),
  );

  FlTitlesData get titles {
    final compact = NumberFormat.compact(locale: _locale);
    final monthName = DateFormat.MMM(_locale);
    final step = months.length > 6 ? 2 : 1;
    return FlTitlesData(
      topTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 44,
          interval: range.step,
          getTitlesWidget: (value, meta) => SideTitleWidget(
            meta: meta,
            child: Text(
              compact.format(value).replaceFirst('-', '−'),
              style: _axis,
            ),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          getTitlesWidget: (value, meta) {
            final i = value.round();
            final last = months.length - 1;
            if (i != value || i < 0 || i > last || (last - i) % step != 0) {
              return const SizedBox.shrink();
            }
            return SideTitleWidget(
              meta: meta,
              child: Text(
                monthName.format(months[i].start),
                style: i == last
                    ? _axis.copyWith(
                        color: _theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      )
                    : _axis,
              ),
            );
          },
        ),
      ),
    );
  }

  /// The ink baseline at zero.
  ExtraLinesData get baseline => ExtraLinesData(
    horizontalLines: [
      HorizontalLine(y: 0, color: _theme.colorScheme.onSurface, strokeWidth: 1),
    ],
  );
}
