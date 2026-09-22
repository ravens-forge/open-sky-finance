import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/app.dart';
import 'package:open_sky_finance/app/now.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/enums/home_section_id.dart';
import 'package:open_sky_finance/data/models/home_section.dart';
import 'package:open_sky_finance/data/repositories/setting_keys.dart';
import 'package:open_sky_finance/data/providers.dart';
import 'package:open_sky_finance/features/onboarding/models/onboarding_steps.dart';

/// Pumps the app on an in-memory database; [onboarded] marks every
/// onboarding step as seen first, and [locale] pins the language instead
/// of following the device.
///
/// Home's sections watch transactions, and their queries block writes made
/// later from `tester.runAsync`, so Home starts with every section hidden
/// unless [showHome]; write what Home should show in [seed], which runs
/// before the app is pumped. The clock stays at [now] (default: when the
/// test starts). [overrides] replace more providers.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  bool onboarded = true,
  String? locale,
  bool showHome = false,
  Future<void> Function(AppDatabase db)? seed,
  DateTime? now,
  List<Override> overrides = const [],
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
  if (!showHome) {
    await tester.runAsync(
      () => db.settingsRepository.setHomeSections([
        for (final id in HomeSectionId.values) HomeSection(id, visible: false),
      ]),
    );
  }
  if (seed != null) await tester.runAsync(() => seed(db));
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      // Fixed, so no clock timer outlives the test.
      nowProvider.overrideWithValue(now ?? DateTime.now()),
      ...overrides,
    ],
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
