import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/app.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/repositories/setting_keys.dart';
import 'package:open_sky_finance/data/providers.dart';
import 'package:open_sky_finance/features/onboarding/models/onboarding_steps.dart';

/// Pumps the app on an in-memory database; [onboarded] marks every
/// onboarding step as seen first, and [locale] pins the language instead
/// of following the device.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  bool onboarded = true,
  String? locale,
}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase(executor: NativeDatabase.memory());
  if (onboarded) {
    await tester.runAsync(
      () => db.settingsRepository.set(
        SettingKeys.onboardingSeenSteps,
        jsonEncode([for (final s in onboardingSteps) s.id]),
      ),
    );
  }
  if (locale != null) {
    await tester.runAsync(
      () => db.settingsRepository.set(SettingKeys.locale, locale),
    );
  }
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
  addTearDown(() async {
    // Unmount first so Drift's stream cleanup timers run inside the test.
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.runAsync(db.close);
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const App()),
  );
  await settle(tester);
  return container;
}

/// Lets the database answer, then finishes animations.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }
}
