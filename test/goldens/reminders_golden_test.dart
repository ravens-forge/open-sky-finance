@Tags(['golden'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/core/widgets/info_tooltip.dart';

import '../pump_app.dart';
import 'demo_data.dart';
import 'golden.dart';

Future<void> _open(
  WidgetTester tester,
  ProviderContainer container,
  String path,
) async {
  container.read(routerProvider).go(path);
  await settle(tester);
}

void main() {
  appGolden(
    'reminders',
    height: 1320,
    seed: seedDemo,
    act: (tester, container, l10n) =>
        _open(tester, container, Routes.reminders),
  );

  appGolden(
    'reminders_empty',
    act: (tester, container, l10n) =>
        _open(tester, container, Routes.reminders),
  );

  appGolden(
    'reminders_tooltip',
    height: 1320,
    seed: seedDemo,
    act: (tester, container, l10n) async {
      await _open(tester, container, Routes.reminders);
      await tester.tap(find.byType(InfoTooltip));
      await settle(tester);
    },
  );

  appGolden(
    'new_reminder',
    height: 1300,
    seed: seedDemo,
    act: (tester, container, l10n) =>
        _open(tester, container, Routes.newReminder),
  );

  // A monthly reminder with two recorded occurrences.
  appGolden(
    'edit_reminder',
    height: 1240,
    seed: seedDemo,
    act: (tester, container, l10n) =>
        _open(tester, container, Routes.reminder(demo['reminder:Rent']!)),
  );
}
