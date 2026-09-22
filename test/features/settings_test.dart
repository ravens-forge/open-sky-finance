import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/enums/transaction_type.dart';
import 'package:open_sky_finance/data/models/transaction_draft.dart';
import 'package:open_sky_finance/data/providers.dart';
import 'package:open_sky_finance/data/repositories/setting_keys.dart';
import 'package:open_sky_finance/features/data_management/pages/erased_page.dart';
import 'package:open_sky_finance/features/onboarding/pages/onboarding_page.dart';
import 'package:open_sky_finance/services/backup/backup_folders.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/test_db.dart';
import '../pump_app.dart';

void main() {
  late ProviderContainer container;
  late AppDatabase db;
  late List<Directory> folders;

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Open Sky Finance',
      packageName: 'com.ravensforge.open_sky_finance',
      version: '1.2.3',
      buildNumber: '4',
      buildSignature: '',
    );
  });

  /// Settings open over "Wallet" (a favorite), an expense and one in the
  /// Trash, with a safety backup and a shared file on disk.
  Future<void> start(WidgetTester tester) async {
    // Tall enough to show every setting at once.
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(800, 2000);
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      final temp = await Directory.systemTemp.createTemp('erase_test');
      addTearDown(() => temp.delete(recursive: true));
      folders = [
        for (final name in ['safety_backups', 'share'])
          await Directory('${temp.path}/$name').create(),
      ];
      for (final folder in folders) {
        await File('${folder.path}/copy.json').writeAsString('{}');
      }
    });
    container = await pumpApp(
      tester,
      overrides: [backupCopyFoldersProvider.overrideWith((_) => folders)],
      seed: (db) async {
        final wallet = await addAssetsAccount(db, 'Wallet');
        await db.assetsAccountsRepository.setFavorite(wallet, true);
        for (final title in ['Bakery', 'Taxi']) {
          final id = ok(
            await db.transactionsRepository.save(
              TransactionDraft(
                type: TransactionType.expense,
                occurredAt: DateTime(2026, 9, 1),
                amount: -m(12),
                assetsAccountId: wallet,
                title: title,
              ),
            ),
          );
          if (title == 'Taxi') await db.transactionsRepository.trash(id);
        }
        await db.settingsRepository.set(SettingKeys.themeMode, 'dark');
        await db.settingsRepository.set(SettingKeys.autoBackupEnabled, 'true');
      },
    );
    db = container.read(appDatabaseProvider);
    container.read(routerProvider).go(Routes.settings);
    await settle(tester);
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.tap(find.text(text).last);
    await settle(tester);
  }

  testWidgets('shows and changes the settings', (tester) async {
    await start(tester);

    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('1 assets account · used by the charts'), findsOneWidget);
    expect(find.text('1 item'), findsOneWidget, reason: 'the Trash');
    expect(find.text('No backup yet'), findsOneWidget);
    await settle(tester);
    expect(find.text('Version 1.2.3'), findsOneWidget);

    await tapText(tester, 'Theme');
    await tapText(tester, 'Light');
    expect(await db.settingsRepository.get(SettingKeys.themeMode), 'light');
    expect(find.text('Light'), findsOneWidget);
  });

  testWidgets('erase all data asks twice, then shows what happened', (
    tester,
  ) async {
    await start(tester);

    await tapText(tester, 'Erase all data');
    expect(find.text('Erase all data?'), findsOneWidget);
    expect(find.text('1 assets account and 1 transaction'), findsOneWidget);
    expect(find.text('0 categories and 1 item in the Trash'), findsOneWidget);
    await tapText(tester, 'Continue');

    expect(find.text('STEP 2 OF 2'), findsOneWidget);
    final erase = find.widgetWithText(OutlinedButton, 'Erase');
    expect(tester.widget<OutlinedButton>(erase).onPressed, isNull);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(erase);
    // Deleting the folders is real IO; the progress line never settles.
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await settle(tester);

    expect(find.byType(ErasedPage), findsOneWidget);
    expect(find.text('A clean ledger.'), findsOneWidget);
    expect(find.textContaining('1 assets account, 1 transaction'), findsOne);
    final counts = await tester.runAsync(db.eraseRepository.counts);
    expect(counts!.assetsAccounts, 1, reason: 'the seeded Cash one');
    expect(counts.transactions + counts.trashed, 0);
    expect(await db.settingsRepository.get(SettingKeys.themeMode), 'dark');
    expect(
      await db.settingsRepository.get(SettingKeys.autoBackupEnabled),
      isNull,
    );
    for (final folder in folders) {
      expect(await tester.runAsync(folder.exists), isFalse);
    }

    await tapText(tester, 'Start setup');
    expect(find.byType(OnboardingPage), findsOneWidget);
  });

  testWidgets('a failed erase keeps the data and says so', (tester) async {
    await start(tester);
    await tester.runAsync(
      () => db.customStatement(
        'CREATE TRIGGER no_seed BEFORE INSERT ON assets_accounts '
        "BEGIN SELECT RAISE(ABORT, 'test'); END",
      ),
    );

    await tapText(tester, 'Erase all data');
    await tapText(tester, 'Continue');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tapText(tester, 'Erase');

    expect(find.text("Couldn't erase your data"), findsOneWidget);
    expect(find.byType(ErasedPage), findsNothing);
    final counts = await tester.runAsync(db.eraseRepository.counts);
    expect(counts!.transactions, 1);
    expect(counts.trashed, 1);
    for (final folder in folders) {
      expect(await tester.runAsync(folder.exists), isTrue);
    }
  });
}
