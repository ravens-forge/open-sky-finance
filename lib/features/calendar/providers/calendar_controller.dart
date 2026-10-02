import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/now.dart';
import '../../../core/dates/year_month.dart';
import '../models/calendar_mode.dart';
import '../models/calendar_selection.dart';
import '../models/calendar_tab.dart';

part 'calendar_controller.g.dart';

/// The calendar's month, selection and tab while the page is open; it starts
/// on today each time the page opens.
@riverpod
class CalendarController extends _$CalendarController {
  @override
  CalendarSelection build() => CalendarSelection.today(ref.read(todayProvider));

  void setMode(CalendarMode mode, int firstDayOfWeek) =>
      state = state.withMode(mode, ref.read(todayProvider), firstDayOfWeek);

  void tap(DateTime day, int firstDayOfWeek) =>
      state = state.tap(day, firstDayOfWeek);

  void showMonth(YearMonth month) => state = state.showMonth(month);

  void showToday(int firstDayOfWeek) =>
      state = state.showToday(ref.read(todayProvider), firstDayOfWeek);

  void setTab(CalendarTab tab) => state = state.withTab(tab);
}
