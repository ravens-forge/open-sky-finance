import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/core/result.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/database/tables/setting_keys.dart';
import 'package:open_sky_finance/data/enums/assets_account_type.dart';
import 'package:open_sky_finance/data/models/assets_account_draft.dart';
import 'package:open_sky_finance/data/providers.dart';
import 'package:open_sky_finance/features/onboarding/models/onboarding_step.dart';
import 'package:open_sky_finance/features/onboarding/providers/onboarding_provider.dart';
import 'package:open_sky_finance/features/onboarding/models/onboarding_steps.dart';

import '../data/test_db.dart';
import '../pump_app.dart';

const _v1 = ['welcome', 'basics', 'firstAssetsAccount'];

// Steps a later version could add.
const _backups = OnboardingStep('autoBackups', (1, 2));
const _newIntro = OnboardingStep('newIntro', (1, 2), newUsersOnly: true);
const _v12 = [...onboardingSteps, _newIntro, _backups];

List<String> ids(List<OnboardingStep> steps) => [for (final s in steps) s.id];

void main() {
  group('planOnboarding', () {
    test('fresh install shows every step', () {
      final plan = planOnboarding(null, hasUserData: false);
      expect(ids(plan.pending), _v1);
      expect(plan.autoSeen, isEmpty);
    });

    test('partial progress resumes at the first unseen step', () {
      final plan = planOnboarding({'welcome'}, hasUserData: false);
      expect(ids(plan.pending), ['basics', 'firstAssetsAccount']);
      expect(plan.autoSeen, isEmpty);
    });

    test('after Skip nothing is pending', () {
      expect(planOnboarding(_v1.toSet(), hasUserData: true).pending, isEmpty);
    });

    test('update shows only the new steps, never new-users-only ones', () {
      final plan = planOnboarding(_v1.toSet(), hasUserData: false, steps: _v12);
      expect(ids(plan.pending), ['autoBackups']);
      expect(plan.autoSeen, {'newIntro'});
    });

    test('fresh install after the update shows every step', () {
      final plan = planOnboarding(null, hasUserData: false, steps: _v12);
      expect(ids(plan.pending), [..._v1, 'newIntro', 'autoBackups']);
    });

    test('existing user without seen steps skips the introduction', () {
      final plan = planOnboarding(null, hasUserData: true, steps: _v12);
      expect(ids(plan.pending), ['autoBackups']);
      expect(plan.autoSeen, {..._v1, 'newIntro'});
    });

    test('unknown ids are ignored', () {
      final plan = planOnboarding({'removedStep'}, hasUserData: false);
      expect(ids(plan.pending), _v1);
    });
  });

  group('onboardingProvider', () {
    late AppDatabase db;
    ProviderContainer start() {
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      return container;
    }

    Future<List<String>?> seen() async {
      final json = await db.settingsRepository.get(
        SettingKeys.onboardingSeenSteps,
      );
      return json == null ? null : List<String>.from(jsonDecode(json) as List);
    }

    setUp(() => db = testDb());

    test('fresh install, then resume after a restart', () async {
      var container = start();
      var session = await container.read(onboardingProvider.future);
      expect(ids(session.steps), _v1);
      expect(session.whatsNew, isFalse);

      await container
          .read(onboardingProvider.notifier)
          .markSeen(OnboardingStep.welcome);
      // The running session keeps its steps.
      expect(ids(container.read(onboardingProvider).value!.steps), _v1);

      container = start();
      session = await container.read(onboardingProvider.future);
      expect(ids(session.steps), ['basics', 'firstAssetsAccount']);
    });

    test('Skip marks every pending step as seen', () async {
      final container = start();
      await container.read(onboardingProvider.future);
      await container.read(onboardingProvider.notifier).finish();

      expect(container.read(onboardingProvider).value!.steps, isEmpty);
      expect(await seen(), unorderedEquals(_v1));
    });

    test('existing user: new-users-only steps are auto-marked', () async {
      await addAssetsAccount(db, 'Checking', openingBalance: m(10));

      final session = await start().read(onboardingProvider.future);
      expect(session.steps, isEmpty);
      expect(await seen(), unorderedEquals(_v1));
    });

    test('first assets account sets the main currency and finishes', () async {
      final container = start();
      await container.read(onboardingProvider.future);

      final result = await container
          .read(onboardingProvider.notifier)
          .createFirstAssetsAccount(
            AssetsAccountDraft(
              name: 'Checking',
              type: AssetsAccountType.bank,
              currency: 'CHF',
              openingBalance: m(250),
              openingBalanceDate: DateTime(2026, 9, 19),
            ),
          );

      final id = ok(result);
      expect((await db.assetsAccountsRepository.findById(id))!.currency, 'CHF');
      expect(await db.settingsRepository.get(SettingKeys.mainCurrency), 'CHF');
      expect(container.read(onboardingProvider).value!.steps, isEmpty);
      expect(await seen(), unorderedEquals(_v1));
    });

    test('invalid first assets account is refused', () async {
      final container = start();
      await container.read(onboardingProvider.future);

      final result = await container
          .read(onboardingProvider.notifier)
          .createFirstAssetsAccount(
            AssetsAccountDraft(
              name: ' ',
              type: AssetsAccountType.bank,
              currency: 'CHF',
              openingBalanceDate: DateTime(2026, 9, 19),
            ),
          );

      expect(result, isA<Err<String, Object>>());
      expect(container.read(onboardingProvider).value!.steps, hasLength(3));
    });
  });

  testWidgets('walks through the steps and lands on Home', (tester) async {
    final container = await pumpApp(tester, onboarded: false);
    final router = container.read(routerProvider);
    expect(find.text('STEP 1 OF 3'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await settle(tester);
    expect(find.text('STEP 2 OF 3'), findsOneWidget);
    expect(find.text('A few basics'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await settle(tester);
    expect(find.text('Add your first assets account'), findsOneWidget);
    expect(find.text('0.00'), findsOneWidget);

    // Nothing is saved without a name.
    await tester.tap(find.text('Start'));
    await settle(tester);
    expect(find.text('Enter a name'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Checking');
    await tester.tap(find.text('Start'));
    await settle(tester);
    expect(router.state.uri.toString(), Routes.home);
  });

  testWidgets('the welcome link opens Backups', (tester) async {
    final router = (await pumpApp(
      tester,
      onboarded: false,
    )).read(routerProvider);

    final link = find.text('Restore a backup or import from Bluecoins');
    await tester.ensureVisible(link);
    await tester.tap(link);
    await settle(tester);
    expect(router.state.uri.toString(), Routes.backups);
  });
}
