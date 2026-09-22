import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/money/format_money.dart';
import '../../../core/widgets/chart_semantics.dart';
import '../models/budget_summary.dart';
import 'chart_legend_item.dart';

/// Full pie: one slice per budget in series order and "Remaining" last in
/// `outline`, with the legend beside it. Tapping a slice calls [onTap].
class BudgetPieChart extends StatelessWidget {
  const BudgetPieChart({
    super.key,
    required this.summary,
    required this.currency,
    required this.onTap,
  });

  final BudgetSummary summary;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final finance = FinanceColors.of(context);
    String money(int micros) =>
        formatMoney(micros, currency: currency, locale: l10n.localeName);
    PieChartSectionData slice(int micros, Color color) => PieChartSectionData(
      // A proportion for display only.
      value: micros.toDouble(),
      color: color,
      radius: 70,
      showTitle: false,
    );

    return ChartSemantics(
      label: l10n.homeBudgetSemantic(
        [
          for (final s in summary.slices)
            l10n.chartPointSemantic(s.name, money(s.spent)),
          l10n.chartPointSemantic(
            l10n.homeBudgetRemaining,
            money(summary.remaining),
          ),
        ].join(', '),
      ),
      child: Row(
        spacing: 18,
        children: [
          SizedBox.square(
            dimension: 140,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 0,
                startDegreeOffset: -90,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    final index = response?.touchedSection?.touchedSectionIndex;
                    if (event is FlTapUpEvent && index != null && index >= 0) {
                      onTap();
                    }
                  },
                ),
                sections: [
                  for (final (i, s) in summary.slices.indexed)
                    if (s.spent > 0) slice(s.spent, finance.series(i)),
                  if (summary.remaining > 0)
                    slice(summary.remaining, finance.chartOther),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                for (final (i, s) in summary.slices.indexed)
                  ChartLegendItem(finance.series(i), s.name),
                ChartLegendItem(
                  finance.chartOther,
                  l10n.homeBudgetRemaining,
                  border: finance.disabled,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
