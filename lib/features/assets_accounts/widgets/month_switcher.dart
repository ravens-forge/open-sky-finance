import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/dates/year_month.dart';
import '../../../core/l10n.dart';

/// ‹ SEPTEMBER 2026 ›
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    super.key,
    required this.month,
    required this.onChanged,
  });

  final YearMonth month;
  final ValueChanged<YearMonth> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        IconButton(
          tooltip: l10n.actionPreviousMonth,
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onChanged(month.plus(-1)),
        ),
        Expanded(
          child: Text(
            DateFormat.yMMMM(l10n.localeName).format(month.start).toUpperCase(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.eyebrow,
          ),
        ),
        IconButton(
          tooltip: l10n.actionNextMonth,
          icon: const Icon(Icons.chevron_right),
          onPressed: () => onChanged(month.plus(1)),
        ),
      ],
    );
  }
}
