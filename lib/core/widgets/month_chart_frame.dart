import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';

import '../dates/year_month.dart';
import '../l10n.dart';
import 'large_text.dart';
import 'month_chart_axes.dart';

/// A monthly chart with a readout row above it: the selected month, its
/// [values] and a "View month" link that drills down. It starts on the last
/// month; a tap anywhere in a month's column selects it and the selection
/// stays, a horizontal drag moves it. The selected column gets a band.
class MonthChartFrame extends HookWidget {
  const MonthChartFrame({
    super.key,
    required this.months,
    required this.height,
    required this.values,
    required this.chart,
    this.onViewMonth,
  });

  final List<YearMonth> months;

  /// Of the chart, month names included.
  final double height;

  /// The readout's figures for the month at an index.
  final List<Widget> Function(int index) values;

  /// The chart with the month at an index selected.
  final Widget Function(int selected) chart;
  final ValueChanged<YearMonth>? onViewMonth;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final last = months.length - 1;
    final picked = useState<int?>(null);
    final selected = (picked.value ?? last).clamp(0, last);
    final left = MonthChartAxes.leftReserved(context);
    final bottom = MonthChartAxes.bottomReserved(context);
    final onView = onViewMonth;
    final large = isLargeText(context);
    final figures = Wrap(
      spacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          DateFormat.yMMM(l10n.localeName).format(months[selected].start),
          style: theme.textTheme.labelLarge!.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        for (final v in values(selected))
          DefaultTextStyle.merge(
            style: const TextStyle(fontWeight: FontWeight.w600),
            child: v,
          ),
      ],
    );
    final link = onView == null
        ? null
        : TextButton.icon(
            onPressed: () => onView(months[selected]),
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.chevron_right, size: 18),
            label: Text(l10n.chartViewMonth),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Semantics(
          liveRegion: true,
          container: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            // Under large text the link goes below, so the figures keep the
            // whole width.
            child: large
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      figures,
                      if (link != null)
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: link,
                        ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: figures),
                      ?link,
                    ],
                  ),
          ),
        ),
        SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slot = (constraints.maxWidth - left) / months.length;
              void pick(Offset at) =>
                  picked.value = ((at.dx - left) / slot).floor().clamp(0, last);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => pick(d.localPosition),
                onHorizontalDragStart: (d) => pick(d.localPosition),
                onHorizontalDragUpdate: (d) => pick(d.localPosition),
                child: Stack(
                  children: [
                    // The chart is not mirrored right to left, nor the band.
                    Positioned(
                      left: left + selected * slot,
                      width: slot,
                      top: 0,
                      bottom: bottom,
                      child: ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    Positioned.fill(child: chart(selected)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
