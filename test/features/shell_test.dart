import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:open_sky_finance/app/app.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/database/tables/setting_keys.dart';
import 'package:open_sky_finance/data/providers.dart';
import 'package:open_sky_finance/features/onboarding/onboarding_steps.dart';

/// Pumps the app on an in-memory database; [onboarded] marks every
/// onboarding step as seen first.
Future<GoRouter> pumpApp(WidgetTester tester, {bool onboarded = true}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase(executor: NativeDatabase.memory());
  if (onboarded) {
    await tester.runAsync(
      () => db.settingsRepository.set(
        SettingKeys.onboardingSeenSteps,
        jsonEncode(onboardingSteps),
      ),
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
  return container.read(routerProvider);
}

/// Lets the database answer, then finishes animations.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }
}

String location(GoRouter router) => router.state.uri.toString();

void main() {
  testWidgets('first launch goes to onboarding; Skip goes Home', (
    tester,
  ) async {
    final router = await pumpApp(tester, onboarded: false);
    expect(location(router), Routes.onboarding);

    await tester.tap(find.text('Skip'));
    await settle(tester);
    expect(location(router), Routes.home);
    expect(find.text('Open Sky Finance'), findsOneWidget);
  });

  testWidgets('tabs, swipe and branch stay in sync', (tester) async {
    final router = await pumpApp(tester);
    expect(location(router), Routes.home);

    await tester.tap(find.text('Transactions'));
    await settle(tester);
    expect(location(router), Routes.transactions);

    await tester.fling(find.byType(TabBarView), const Offset(-400, 0), 1000);
    await settle(tester);
    expect(location(router), Routes.reminders);

    router.go(Routes.labels);
    await settle(tester);
    final tabs = tester.widget<TabBar>(find.byType(TabBar)).controller!;
    expect(tabs.index, 6);
  });

  testWidgets('FAB opens the editor above the shell', (tester) async {
    final router = await pumpApp(tester);

    await tester.tap(find.text('Add'));
    await settle(tester);
    expect(location(router), Routes.newTransaction());
    expect(find.text('New transaction'), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);

    await tester.tap(find.byTooltip('Close'));
    await settle(tester);
    expect(location(router), Routes.home);
  });

  testWidgets('drawer opens other pages', (tester) async {
    final router = await pumpApp(tester);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await settle(tester);
    await tester.tap(find.text('Categories'));
    await settle(tester);
    expect(location(router), Routes.categories);
  });

  testWidgets('unknown IDs and paths show not found', (tester) async {
    final router = await pumpApp(tester);

    for (final path in [
      Routes.transaction('missing'),
      Routes.assetsAccount('missing'),
      Routes.category('missing'),
      '/nowhere',
    ]) {
      router.go(path);
      await settle(tester);
      expect(find.text('Nothing here'), findsOneWidget, reason: path);
    }

    await tester.tap(find.text('Go to Home'));
    await settle(tester);
    expect(location(router), Routes.home);
  });
}
