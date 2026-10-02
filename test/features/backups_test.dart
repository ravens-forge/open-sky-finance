import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/providers.dart';
import 'package:open_sky_finance/data/repositories/setting_keys.dart';
import 'package:open_sky_finance/features/settings/providers/settings_providers.dart';
import 'package:open_sky_finance/services/backup/backup_folder_access.dart';
import 'package:open_sky_finance/services/backup/backup_folders.dart';
import 'package:open_sky_finance/services/backup/models/backup_folder.dart';

import '../data/test_db.dart';
import '../pump_app.dart';
import '../services/fake_backup_folder.dart';

const _drive = BackupFolder(ref: 'content://tree/1', name: 'Drive › Backups');

/// Lets real work (isolates, files) run until [finder] shows up.
Future<void> settleUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
  await settle(tester);
}

void main() {
  late ProviderContainer container;
  late AppDatabase db;
  late FakeBackupFolder folder;

  Future<void> start(
    WidgetTester tester, {
    Future<void> Function(AppDatabase db)? seed,
    bool reachable = true,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(800, 2400);
    addTearDown(tester.view.reset);
    late List<Directory> folders;
    await tester.runAsync(() async {
      final temp = await Directory.systemTemp.createTemp('backups_test');
      addTearDown(() => temp.delete(recursive: true));
      folders = [
        for (final name in ['safety_backups', 'share', 'bluecoins'])
          Directory('${temp.path}/$name'),
      ];
    });
    folder = FakeBackupFolder(picked: _drive)..reachable = reachable;
    container = await pumpApp(
      tester,
      now: DateTime(2026, 9, 17, 10, 30),
      overrides: [
        backupCopyFoldersProvider.overrideWith((_) => folders),
        backupFolderAccessProvider.overrideWithValue(folder),
        appVersionProvider.overrideWith((_) async => '1.2.3'),
      ],
      seed: (db) async {
        await addAssetsAccount(db, 'Wallet');
        await seed?.call(db);
      },
    );
    db = container.read(appDatabaseProvider);
  }

  Future<void> openBackups(WidgetTester tester) async {
    container.read(routerProvider).go(Routes.backups);
    await settle(tester);
  }

  testWidgets('turning automatic backups on picks a folder and backs up', (
    tester,
  ) async {
    await start(tester);
    await openBackups(tester);
    expect(find.text('Folder'), findsNothing);

    await tester.tap(find.text('Runs when you open or leave the app'));
    await settleUntil(tester, find.text('Backup saved to the folder'));

    expect(find.text('Backup saved to the folder'), findsOneWidget);
    expect(folder.files.keys, ['open-sky-finance-backup-20260917-103000.json']);
    expect(find.text('Drive › Backups'), findsOneWidget);
    expect(
      find.textContaining('Automatic · Drive › Backups · '),
      findsOneWidget,
    );
    expect(find.text('Weekly'), findsOneWidget);

    await tester.tap(find.text('Frequency'));
    await settle(tester);
    await tester.tap(find.text('Monthly'));
    await settle(tester);
    expect(
      await db.settingsRepository.get(SettingKeys.autoBackupFrequency),
      'monthly',
    );

    await tester.tap(find.text('Keep'));
    await settle(tester);
    await tester.tap(find.text('Last 3 backups'));
    await settle(tester);
    expect(find.text('Last 3 backups, older ones are deleted'), findsOneWidget);
  });

  testWidgets('an unreachable folder pauses with a dialog on open', (
    tester,
  ) async {
    await start(
      tester,
      reachable: false,
      seed: (db) async {
        for (final (key, value) in [
          (SettingKeys.autoBackupEnabled, 'true'),
          (SettingKeys.autoBackupFolder, _drive.ref),
          (SettingKeys.autoBackupFolderName, _drive.name),
          (
            SettingKeys.lastBackupAt,
            DateTime.utc(2026, 9, 1).toIso8601String(),
          ),
        ]) {
          await db.settingsRepository.set(key, value);
        }
      },
    );
    // The app was opened: the due backup runs.
    await settleUntil(tester, find.text('Automatic backups are paused'));
    expect(find.text('Automatic backups are paused'), findsOneWidget);
    expect(
      await db.settingsRepository.get(SettingKeys.autoBackupPaused),
      'true',
    );

    await tester.tap(find.text('Later'));
    await settle(tester);
    container.read(routerProvider).go(Routes.settings);
    await settle(tester);
    expect(
      find.text('Automatic backups paused: choose the folder again'),
      findsOneWidget,
    );

    await openBackups(tester);
    expect(
      find.textContaining('Automatic backups are paused.'),
      findsOneWidget,
    );
    folder.reachable = true;
    await tester.tap(find.text('Choose folder'));
    await settleUntil(tester, find.text('Backup saved to the folder'));
    expect(
      await db.settingsRepository.get(SettingKeys.autoBackupPaused),
      isNull,
    );
    expect(find.textContaining('Automatic backups are paused.'), findsNothing);
  });

  testWidgets('a backup password needs 8 characters typed twice', (
    tester,
  ) async {
    await start(tester);
    await openBackups(tester);
    expect(find.textContaining('Backups are not encrypted.'), findsOneWidget);

    await tester.ensureVisible(find.text('Encrypt backups'));
    await tester.tap(find.text('Encrypt backups'));
    await settle(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, 'short');
    await tester.enterText(fields.last, 'other');
    await tester.tap(find.text('Encrypt'));
    await settle(tester);
    expect(find.text('Use at least 8 characters'), findsOneWidget);
    expect(find.text("The passwords don't match"), findsOneWidget);

    await tester.enterText(fields.first, 'long enough');
    await tester.enterText(fields.last, 'long enough');
    await tester.tap(find.text('Encrypt'));
    await settleUntil(tester, find.text('Next backups will be encrypted'));
    expect(find.text('Next backups will be encrypted'), findsOneWidget);
    expect(await db.settingsRepository.get(SettingKeys.backupKey), isNotNull);
    expect(find.text('Change password'), findsOneWidget);
    expect(find.textContaining('Backups are not encrypted.'), findsNothing);

    await tester.tap(find.text('Encrypt backups'));
    await settle(tester);
    expect(await db.settingsRepository.get(SettingKeys.backupKey), isNull);
  });
}
