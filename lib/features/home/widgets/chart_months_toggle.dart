import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../providers/home_controller.dart';

/// "Last 6 months" caption of the monthly charts; tapping switches every chart
/// between 6 and 12 months.
class ChartMonthsToggle extends ConsumerWidget {
  const ChartMonthsToggle({super.key, required this.months});

  final int months;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final other = months == 12 ? 6 : 12;
    return Semantics(
      button: true,
      onTapHint: l10n.homeShowMonths(other),
      child: InkWell(
        onTap: () =>
            ref.read(homeControllerProvider.notifier).setChartMonths(other),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.homeLastMonths(months)),
              const Icon(Icons.unfold_more, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
