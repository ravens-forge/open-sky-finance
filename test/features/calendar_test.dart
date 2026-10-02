import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/core/dates/year_month.dart';
import 'package:open_sky_finance/data/repositories/setting_keys.dart';
import 'package:open_sky_finance/features/calendar/models/calendar_grid.dart';
import 'package:open_sky_finance/features/calendar/models/calendar_mode.dart';
import 'package:open_sky_finance/features/calendar/models/calendar_period.dart';
import 'package:open_sky_finance/features/calendar/models/calendar_selection.dart';
import 'package:open_sky_finance/features/net_income/models/net_income_period.dart';

import '../pump_app.dart';

const _monday = DateTime.monday;
const _sunday = DateTime.sunday;

void main() {
  group('CalendarPeriod', () {
    test('a day runs from its midnight to the next', () {
      final day = CalendarPeriod.day(DateTime(2026, 9, 17, 10, 30));
      expect(day.start, DateTime(2026, 9, 17));
      expect(day.end, DateTime(2026, 9, 18));
      expect(day.isSingleDay, isTrue);
    });

    test('weeks start on the chosen day, across months and years', () {
      final monday = CalendarPeriod.week(DateTime(2026, 9, 30), _monday);
      expect(monday.start, DateTime(2026, 9, 28));
      expect(monday.lastDay, DateTime(2026, 10, 4));
      expect(monday.end, DateTime(2026, 10, 5));

      final sunday = CalendarPeriod.week(DateTime(2026, 9, 17), _sunday);
      expect(sunday.start, DateTime(2026, 9, 13));
      expect(sunday.lastDay, DateTime(2026, 9, 19));
      // A Sunday starts its own week.
      expect(
        CalendarPeriod.week(DateTime(2026, 9, 13), _sunday).start,
        DateTime(2026, 9, 13),
      );
      // …and ends the Monday one.
      expect(
        CalendarPeriod.week(DateTime(2026, 9, 13), _monday).start,
        DateTime(2026, 9, 7),
      );

      final newYear = CalendarPeriod.week(DateTime(2027, 1, 1), _monday);
      expect(newYear.start, DateTime(2026, 12, 28));
      expect(newYear.end, DateTime(2027, 1, 4));
    });

    test('a range takes its ends in either order, both included', () {
      final range = CalendarPeriod.range(
        DateTime(2026, 9, 15),
        DateTime(2026, 9, 1),
      );
      expect(
        range,
        CalendarPeriod.range(DateTime(2026, 9, 1), DateTime(2026, 9, 15)),
      );
      expect(range.start, DateTime(2026, 9, 1));
      expect(range.end, DateTime(2026, 9, 16));
      expect(range.contains(DateTime(2026, 9, 15)), isTrue);
      expect(range.contains(DateTime(2026, 9, 16)), isFalse);
      expect(range.contains(DateTime(2026, 8, 31)), isFalse);
    });

    test('the Net income period keeps a month a month', () {
      final month = YearMonth(2026, 9);
      expect(
        CalendarPeriod.month(month).netIncomePeriod,
        NetIncomePeriod.month(month),
      );
      expect(
        CalendarPeriod.week(DateTime(2026, 9, 17), _monday).netIncomePeriod,
        NetIncomePeriod.range(DateTime(2026, 9, 14), DateTime(2026, 9, 20)),
      );
    });
  });

  test('the grid shows six weeks from the week of the 1st', () {
    final monday = CalendarGrid(YearMonth(2026, 9), _monday);
    expect(monday.start, DateTime(2026, 8, 31));
    expect(monday.days, hasLength(42));
    expect(monday.days.last, DateTime(2026, 10, 11));
    expect(monday.end, DateTime(2026, 10, 12));

    expect(
      CalendarGrid(YearMonth(2026, 9), _sunday).start,
      DateTime(2026, 8, 30),
    );
    // A month starting on the first day of week starts the grid.
    expect(
      CalendarGrid(YearMonth(2026, 6), _monday).start,
      DateTime(2026, 6, 1),
    );
  });

  group('CalendarSelection', () {
    final today = DateTime(2026, 9, 17);
    final start = CalendarSelection.today(today);

    test('switching modes keeps the selected place', () {
      final week = start.withMode(CalendarMode.week, today, _monday);
      expect(week.period, CalendarPeriod.week(today, _monday));
      final month = week.withMode(CalendarMode.month, today, _monday);
      expect(month.period, CalendarPeriod.month(YearMonth(2026, 9)));
      // Back to Day: today, which the month holds.
      expect(
        month.withMode(CalendarMode.day, today, _monday).period,
        start.period,
      );
      // Another month: its first day.
      final october = month.showMonth(YearMonth(2026, 10));
      expect(october.period, CalendarPeriod.month(YearMonth(2026, 10)));
      expect(
        october.withMode(CalendarMode.day, today, _monday).period,
        CalendarPeriod.day(DateTime(2026, 10, 1)),
      );
      // A range keeps the days.
      expect(
        week.withMode(CalendarMode.range, today, _monday).period,
        CalendarPeriod.range(DateTime(2026, 9, 14), DateTime(2026, 9, 20)),
      );
    });

    test('a range needs two taps, in either order', () {
      final range = start.withMode(CalendarMode.range, today, _monday);
      final first = range.tap(DateTime(2026, 9, 15), _monday);
      expect(first.rangeStart, DateTime(2026, 9, 15));
      expect(first.period.isSingleDay, isTrue);
      final second = first.tap(DateTime(2026, 9, 1), _monday);
      expect(second.rangeStart, isNull);
      expect(
        second.period,
        CalendarPeriod.range(DateTime(2026, 9, 1), DateTime(2026, 9, 15)),
      );
      // A third tap starts a new range.
      expect(second.tap(DateTime(2026, 9, 3), _monday).rangeStart, isNotNull);
    });

    test('previous and next move the month; Today comes back', () {
      final day = start.tap(DateTime(2026, 9, 3), _monday);
      final next = day.showMonth(YearMonth(2026, 10));
      expect(next.month, YearMonth(2026, 10));
      expect(next.period, day.period);
      final back = next.showToday(today, _monday);
      expect(back.month, YearMonth(2026, 9));
      expect(back.period, CalendarPeriod.day(today));
    });
  });

  group('page', () {
    final now = DateTime(2026, 9, 17, 10, 30);

    Future<ProviderContainer> open(
      WidgetTester tester, {
      int? firstDayOfWeek,
    }) async {
      // Tall enough for the grid and the panel without scrolling.
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(390, 1600);
      addTearDown(tester.view.reset);
      final container = await pumpApp(
        tester,
        locale: 'en',
        now: now,
        seed: (db) async {
          if (firstDayOfWeek != null) {
            await db.settingsRepository.set(
              SettingKeys.firstDayOfWeek,
              '$firstDayOfWeek',
            );
          }
        },
      );
      unawaited(container.read(routerProvider).push(Routes.calendar));
      await settle(tester);
      return container;
    }

    Future<void> tapText(WidgetTester tester, String text) async {
      await tester.ensureVisible(find.text(text).first);
      await tester.tap(find.text(text).first);
      await settle(tester);
    }

    Future<void> tapDay(WidgetTester tester, String date) async {
      final cell = find.bySemanticsLabel(RegExp('^$date\\b'));
      await tester.ensureVisible(cell);
      await tester.tap(cell);
      await settle(tester);
    }

    testWidgets('modes keep a sensible selection', (tester) async {
      await open(tester, firstDayOfWeek: _monday);
      expect(find.text('Thursday, September 17'), findsOneWidget);
      await tapText(tester, 'Week');
      expect(find.text('Sep 14 – Sep 20, 2026'), findsOneWidget);
      await tapText(tester, 'Month');
      expect(find.text('September 2026'), findsOneWidget);
      await tapText(tester, 'Day');
      expect(find.text('Thursday, September 17'), findsOneWidget);
    });

    testWidgets('a range needs two taps and takes them in either order', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await open(tester);
      await tapText(tester, 'Range');
      await tapDay(tester, 'September 15');
      expect(find.text('Tuesday, September 15'), findsOneWidget);
      await tapDay(tester, 'September 1');
      expect(find.text('Sep 1 – Sep 15, 2026'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('weeks start on the first day of week from settings', (
      tester,
    ) async {
      await open(tester, firstDayOfWeek: _sunday);
      await tapText(tester, 'Week');
      expect(find.text('Sep 13 – Sep 19, 2026'), findsOneWidget);
    });

    testWidgets('Today selects today and shows its month', (tester) async {
      final semantics = tester.ensureSemantics();
      await open(tester);
      await tester.tap(find.byTooltip('Next month'));
      await settle(tester);
      expect(find.text('OCTOBER 2026'), findsOneWidget);
      await tapDay(tester, 'October 8');
      expect(find.text('Thursday, October 8'), findsOneWidget);
      await tapText(tester, 'Today');
      expect(find.text('SEPTEMBER 2026'), findsOneWidget);
      expect(find.text('Thursday, September 17'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('Add shows only on Transactions and starts on the day', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await open(tester);
      await tapDay(tester, 'September 20');
      expect(find.text('Add'), findsOneWidget);
      await tapText(tester, 'Net income');
      expect(find.text('Add'), findsNothing);
      await tapText(tester, 'Transactions');
      await tester.tap(find.text('Add'));
      await settle(tester);
      expect(find.text('Sep 20, 2026'), findsOneWidget);
      semantics.dispose();
    });
  });
}
