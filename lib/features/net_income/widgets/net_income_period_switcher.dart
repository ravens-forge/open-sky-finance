import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/l10n.dart';
import '../models/net_income_period.dart';

class NetIncomePeriodSwitcher extends StatelessWidget {
  const NetIncomePeriodSwitcher({
    super.key,
    required this.period,
    required this.onChanged,
    this.onPick,
  });

  final NetIncomePeriod period;
  final ValueChanged<NetIncomePeriod> onChanged;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = Text(
      _label(period, l10n).toUpperCase(),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.eyebrow,
    );
    final hasArrows = period.kind != NetIncomePeriodKind.range;
    return Row(
      children: [
        IconButton(
          tooltip: l10n.netIncomePreviousPeriod,
          icon: const Icon(Icons.chevron_left),
          onPressed: hasArrows ? () => onChanged(period.previous) : null,
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
          tooltip: l10n.netIncomeNextPeriod,
          icon: const Icon(Icons.chevron_right),
          onPressed: hasArrows ? () => onChanged(period.next) : null,
        ),
      ],
    );
  }

  static String _label(NetIncomePeriod period, AppLocalizations l10n) =>
      switch (period.kind) {
        NetIncomePeriodKind.month => DateFormat.yMMMM(
          l10n.localeName,
        ).format(period.start),
        NetIncomePeriodKind.quarter => l10n.netIncomeQuarterLabel(
          period.quarter!,
          period.year!,
        ),
        NetIncomePeriodKind.year => period.year!.toString(),
        NetIncomePeriodKind.range => l10n.netIncomeRangeLabel(
          DateFormat.yMMMd(l10n.localeName).format(period.start),
          DateFormat.yMMMd(l10n.localeName)
              .format(period.end.subtract(const Duration(days: 1))),
        ),
      };
}
