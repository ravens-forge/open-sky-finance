import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/main_currency.dart';
import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../models/home_section_place.dart';
import '../providers/home_controller.dart';
import '../providers/home_providers.dart';
import 'chart_empty_note.dart';
import 'chart_months_toggle.dart';
import 'home_section_frame.dart';
import 'net_income_chart.dart';

class NetIncomeSection extends ConsumerWidget {
  const NetIncomeSection({super.key, required this.place});

  final HomeSectionPlace place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final months = ref.watch(homeChartMonthsProvider).value ?? 6;
    final flow = ref.watch(homeCashFlowProvider(months)).value;
    final currency = ref.watch(mainCurrencyProvider).value;
    return HomeSectionFrame(
      title: l10n.homeSectionNetIncome,
      place: place,
      caption: ChartMonthsToggle(months: months),
      child: switch ((flow, currency)) {
        (final flow?, final currency?) when flow.any((m) => m.net != 0) =>
          NetIncomeChart(
            months: flow,
            currency: currency,
            onMonthTap: (month) {
              ref.read(homeControllerProvider.notifier).drillDown(month);
              context.go(Routes.transactions);
            },
          ),
        (_?, _?) => ChartEmptyNote(l10n.homeCashFlowEmpty),
        _ => const SizedBox(height: 150),
      },
    );
  }
}
