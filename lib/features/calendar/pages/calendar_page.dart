import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/now.dart';
import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/month_switcher.dart';
import '../../../core/widgets/segmented_filter.dart';
import '../../settings/widgets/preference_pickers.dart';
import '../../shell/widgets/add_fab.dart';
import '../models/calendar_grid.dart';
import '../models/calendar_markers.dart';
import '../models/calendar_mode.dart';
import '../models/calendar_tab.dart';
import '../providers/calendar_controller.dart';
import '../providers/calendar_providers.dart';
import '../widgets/calendar_legend.dart';
import '../widgets/calendar_month_grid.dart';
import '../widgets/calendar_period_panel.dart';

/// A month grid with markers per day, and the selected day, week, month or
/// range with its transactions, reminders, net income and balance sheet.
class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final firstDay = firstDayOfWeek(context, ref);
    final today = ref.watch(todayProvider);
    final selection = ref.watch(calendarControllerProvider);
    final controller = ref.read(calendarControllerProvider.notifier);
    final period = selection.period;
    final markers =
        ref.watch(calendarMarkersProvider(selection.month, firstDay)).value ??
        CalendarMarkers.empty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pageCalendar),
        actions: [
          IconButton(
            tooltip: l10n.actionSearch,
            icon: const Icon(Icons.search),
            onPressed: () => context.go(Routes.transactions),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 6),
            child: OutlinedButton(
              onPressed: () => controller.showToday(firstDay),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: Theme.of(context).textTheme.labelLarge!
                    .copyWith(fontSize: 13),
              ),
              child: Text(l10n.calendarToday),
            ),
          ),
        ],
      ),
      floatingActionButton: selection.tab == CalendarTab.transactions
          ? AddFab(date: period.contains(today) ? today : period.start)
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SegmentedFilter<CalendarMode>(
              options: [
                (CalendarMode.day, l10n.calendarModeDay),
                (CalendarMode.week, l10n.calendarModeWeek),
                (CalendarMode.month, l10n.calendarModeMonth),
                (CalendarMode.range, l10n.calendarModeRange),
              ],
              selected: selection.mode,
              onChanged: (mode) => controller.setMode(mode, firstDay),
            ),
          ),
          const SizedBox(height: 6),
          MonthSwitcher(
            month: selection.month,
            onChanged: controller.showMonth,
          ),
          CalendarMonthGrid(
            grid: CalendarGrid(selection.month, firstDay),
            period: period,
            markers: markers,
            today: today,
            firstDayOfWeek: firstDay,
            onTap: (day) => controller.tap(day, firstDay),
          ),
          const CalendarLegend(),
          CalendarPeriodPanel(
            period: period,
            tab: selection.tab,
            onTab: controller.setTab,
          ),
        ],
      ),
    );
  }
}
