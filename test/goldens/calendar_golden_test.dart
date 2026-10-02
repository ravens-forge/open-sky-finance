@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/core/l10n.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/repositories/setting_keys.dart';
import 'package:open_sky_finance/features/calendar/providers/calendar_controller.dart';

import '../pump_app.dart';
import 'demo_data.dart';
import 'golden.dart';

/// The demo, with weeks starting on Monday in every language and the
/// savings of September 16 recorded from their reminder.
Future<void> _seed(AppDatabase db) async {
  await seedDemo(db);
  await db.customStatement(
    "UPDATE transactions SET reminder_id = ? WHERE title = 'Monthly savings' "
    "AND occurred_at LIKE '2026-09-16%'",
    [demo['reminder:Monthly savings']],
  );
  await db.settingsRepository.set(
    SettingKeys.firstDayOfWeek,
    '${DateTime.monday}',
  );
}

/// Opens the calendar, then taps [mode] and [tab] when given.
Future<void> Function(WidgetTester, ProviderContainer, AppLocalizations)
_calendar({
  String Function(AppLocalizations l10n)? mode,
  String Function(AppLocalizations l10n)? tab,
  List<DateTime> days = const [],
}) => (tester, container, l10n) async {
  unawaited(container.read(routerProvider).push(Routes.calendar));
  await settle(tester);
  if (mode != null) {
    await tester.tap(find.text(mode(l10n)));
    await settle(tester);
  }
  for (final day in days) {
    container
        .read(calendarControllerProvider.notifier)
        .tap(day, DateTime.monday);
    await settle(tester);
  }
  if (tab != null) {
    final label = find.descendant(
      of: find.byType(TabBar),
      matching: find.text(tab(l10n)),
    );
    await tester.ensureVisible(label);
    await tester.pumpAndSettle();
    await tester.tap(label);
    await settle(tester);
  }
};

void main() {
  appGolden('calendar_day', height: 1100, seed: _seed, act: _calendar());

  appGolden(
    'calendar_week_reminders',
    height: 1100,
    seed: _seed,
    act: _calendar(
      mode: (l10n) => l10n.calendarModeWeek,
      tab: (l10n) => l10n.pageReminders,
    ),
  );

  appGolden(
    'calendar_month_net_income',
    height: 1400,
    seed: _seed,
    act: _calendar(
      mode: (l10n) => l10n.calendarModeMonth,
      tab: (l10n) => l10n.pageNetIncome,
    ),
  );

  appGolden(
    'calendar_range_balance_sheet',
    height: 1500,
    seed: _seed,
    act: _calendar(
      mode: (l10n) => l10n.calendarModeRange,
      days: [DateTime(2026, 9, 15), DateTime(2026, 9, 1)],
      tab: (l10n) => l10n.pageBalanceSheet,
    ),
  );
}
