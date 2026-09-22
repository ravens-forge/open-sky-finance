import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../dates/year_month.dart';
import '../l10n.dart';

/// Reads a chart aloud as [label] (its numbers) instead of its marks; with
/// [onMonthTap], each month's drill-down is also a screen reader action.
class ChartSemantics extends StatelessWidget {
  const ChartSemantics({
    super.key,
    required this.label,
    required this.child,
    this.months = const [],
    this.onMonthTap,
  });

  final String label;
  final List<YearMonth> months;
  final ValueChanged<YearMonth>? onMonthTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final monthLong = DateFormat.yMMMM(l10n.localeName);
    final onTap = onMonthTap;
    return Semantics(
      container: true,
      label: label,
      customSemanticsActions: onTap == null
          ? null
          : {
              for (final m in months)
                CustomSemanticsAction(
                  label: l10n.chartOpenMonth(monthLong.format(m.start)),
                ): () =>
                    onTap(m),
            },
      child: ExcludeSemantics(child: child),
    );
  }
}
