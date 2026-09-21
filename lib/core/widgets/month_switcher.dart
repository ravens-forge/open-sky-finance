import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../dates/year_month.dart';
import '../l10n.dart';

/// ‹ SEPTEMBER 2026 ›. With [onPick] the month itself is a button that opens
/// a month picker.
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    super.key,
    required this.month,
    required this.onChanged,
    this.onPick,
  });

  final YearMonth month;
  final ValueChanged<YearMonth> onChanged;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = Text(
      DateFormat.yMMMM(l10n.localeName).format(month.start).toUpperCase(),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.eyebrow,
    );
    return Row(
      children: [
        IconButton(
          tooltip: l10n.actionPreviousMonth,
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onChanged(month.plus(-1)),
        ),
        Expanded(
          child: onPick == null
              ? label
              : TextButton.icon(
                  onPressed: onPick,
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.expand_more, size: 16),
                  label: label,
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
