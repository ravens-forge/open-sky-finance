import 'package:flutter/material.dart';

import '../../../core/finance_colors.dart';
import '../../../data/enums/transaction_type.dart';
import 'calendar_marker.dart';

/// A day of the grid: its number, the selection (an ink disc, a band, or a
/// ring for today) and its markers.
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.day,
    required this.semanticsLabel,
    required this.types,
    required this.reminderDue,
    required this.onTap,
    this.outside = false,
    this.today = false,
    this.selected = false,
    this.filled = false,
    this.bandStart = false,
    this.bandEnd = false,
  });

  final DateTime day;
  final String semanticsLabel;
  final List<TransactionType> types;
  final bool reminderDue;
  final VoidCallback onTap;

  /// Not in the month shown: muted.
  final bool outside;
  final bool today;

  /// In the selected period.
  final bool selected;

  /// The selected day, or an end of a week or range.
  final bool filled;

  /// The band of a week or range runs into the previous or next cell.
  final bool bandStart;
  final bool bandEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final finance = FinanceColors.of(context);
    final band = scheme.primaryContainer;
    final ringed = today && !filled;
    Widget half(bool on) =>
        Expanded(child: ColoredBox(color: on ? band : Colors.transparent));

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: semanticsLabel,
      child: InkWell(
        onTap: onTap,
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              spacing: 2,
              children: [
                SizedBox(
                  height: 36,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [half(bandStart), half(bandEnd)],
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled
                              ? scheme.onSurface
                              : bandStart || bandEnd
                              ? band
                              : null,
                          border: ringed
                              ? Border.all(color: scheme.onSurface, width: 1.5)
                              : null,
                        ),
                        child: Text(
                          '${day.day}',
                          maxLines: 1,
                          style: Theme.of(context).textTheme.bodyLarge!
                              .copyWith(
                                height: 1,
                                color: filled
                                    ? scheme.surface
                                    : outside
                                    ? finance.muted
                                    : scheme.onSurface,
                                fontWeight: filled || ringed
                                    ? FontWeight.w700
                                    : null,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 5,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 2,
                    children: [
                      for (final type in types)
                        CalendarMarker(
                          color: switch (type) {
                            TransactionType.income => finance.income,
                            TransactionType.expense => finance.expense,
                            _ => finance.transfer,
                          },
                        ),
                      if (reminderDue)
                        CalendarMarker(color: finance.warning, ring: true),
                    ],
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
