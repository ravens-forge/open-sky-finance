import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/providers.dart';
import 'package:open_sky_finance/data/repositories/setting_keys.dart';
import 'package:open_sky_finance/features/data_management/providers/backup_controller.dart';
import 'package:open_sky_finance/features/settings/providers/settings_providers.dart';
import 'package:open_sky_finance/services/backup/backup_folder_access.dart';
import 'package:open_sky_finance/services/backup/backup_folders.dart';
import 'package:open_sky_finance/services/backup/models/backup_folder.dart';

import '../data/test_db.dart';
import '../pump_app.dart';
import '../services/bluecoins_fixture.dart';
import '../services/fake_backup_folder.dart';
import 'fake_file_picker.dart';

const _drive = BackupFolder(ref: 'content://tree/1', name: 'Drive › Backups');

void main() {
  late ProviderContainer container;
  late AppDatabase db;
  late FakeBackupFolder folder;
  // Safety backups, share copies and Bluecoins copies.
  late List<Directory> folders;

  Future<void> start(
    WidgetTester tester, {
    Future<void> Function(AppDatabase db)? seed,
    bool reachable = true,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(800, 2400);
    addTearDown(tester.view.reset);
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

  Future<List<String>> assetsAccountNames(WidgetTester tester) async => [
    for (final row in (await tester.runAsync(
      () => db.customSelect('SELECT name FROM assets_accounts').get(),
    ))!)
      row.read<String>('name'),
  ];

  Future<void> saveToFile(WidgetTester tester) async {
    await tester.tap(find.text('Save to…'));
    await settleUntil(tester, find.textContaining('Backup saved: '));
  }

  Future<void> restoreFromFile(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Restore from file…'));
    await tester.tap(find.text('Restore from file…'));
  }

  testWidgets('Save to… records the backup, a cancelled dialog does not', (
    tester,
  ) async {
    final picker = FakeFilePicker.install()..cancelSave = true;
    await start(tester);
    await openBackups(tester);

    await tester.tap(find.text('Save to…'));
    await settleWhen(tester, () => picker.saveDialogs == 1);
    expect(find.textContaining('Backup saved'), findsNothing);
    expect(await db.settingsRepository.get(SettingKeys.lastBackupAt), isNull);

    picker.cancelSave = false;
    await saveToFile(tester);
    final name = picker.saved.keys.single;
    expect(name, startsWith('open-sky-finance-backup-'));
    expect(find.text('Backup saved: $name'), findsOneWidget);
    expect(
      await db.settingsRepository.get(SettingKeys.lastBackupDestination),
      'saved',
    );
    expect(find.textContaining('Saved to a file · '), findsOneWidget);
    // Plain JSON while no password is set.
    expect(utf8.decode(picker.saved[name]!), contains('"Wallet"'));
  });

  testWidgets('Restore from file previews the backup, replaces the data '
      'after a safety backup and goes Home', (tester) async {
    final picker = FakeFilePicker.install();
    await start(tester);
    await openBackups(tester);
    await saveToFile(tester);
    final name = picker.saved.keys.single;
    // Added after the backup: the restore takes it away.
    await tester.runAsync(() => addAssetsAccount(db, 'Later'));

    // Cancel leaves everything as it was.
    picker.pick(name, picker.saved[name]!);
    await restoreFromFile(tester);
    await settleUntil(tester, find.text('Restore backup'));
    expect(find.text(name), findsOneWidget);
    expect(
      find.textContaining('Your current data will be replaced.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(await assetsAccountNames(tester), contains('Later'));
    expect(folders.first.existsSync(), isFalse);

    // Change picks another file, then the restore runs.
    picker
      ..pick(name, picker.saved[name]!)
      ..pick('copy.json', picker.saved[name]!);
    await restoreFromFile(tester);
    await settleUntil(tester, find.text('Restore backup'));
    await tester.tap(find.text('Change'));
    await settleUntil(tester, find.text('copy.json'));
    await tester.tap(find.text('Replace and restore'));
    await settleUntil(tester, find.text('Backup restored'));

    expect(find.text('Backup restored'), findsOneWidget);
    expect(find.text('Restore backup'), findsNothing);
    final names = await assetsAccountNames(tester);
    expect(names, contains('Wallet'));
    expect(names, isNot(contains('Later')));
    expect(folders.first.listSync(), hasLength(1));
    expect(
      container
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .toString(),
      Routes.home,
    );
  });

  testWidgets('a file that is not a backup is refused and changes nothing', (
    tester,
  ) async {
    final picker = FakeFilePicker.install()
      ..pick('notes.txt', utf8.encode('not a backup'));
    await start(tester);
    await openBackups(tester);

    await restoreFromFile(tester);
    await settleUntil(tester, find.text("This file can't be restored"));
    expect(
      find.textContaining('This file is not an Open Sky Finance backup.'),
      findsOneWidget,
    );
    expect(picker.picks, isEmpty);
    expect(await assetsAccountNames(tester), contains('Wallet'));
    expect(folders.first.existsSync(), isFalse);
  });

  testWidgets('an encrypted backup asks for its password until it opens', (
    tester,
  ) async {
    final picker = FakeFilePicker.install();
    await start(tester);
    await tester.runAsync(
      () => container
          .read(backupControllerProvider.notifier)
          .setPassword('long enough'),
    );
    await openBackups(tester);
    await saveToFile(tester);
    final name = picker.saved.keys.single;
    // Nothing readable in the file.
    expect(
      utf8.decode(picker.saved[name]!, allowMalformed: true),
      isNot(contains('Wallet')),
    );

    picker.pick(name, picker.saved[name]!);
    await restoreFromFile(tester);
    await settleUntil(tester, find.text('This backup is encrypted'));
    await tester.enterText(find.byType(TextField).last, 'another one');
    await tester.tap(find.text('Open'));
    await settleUntil(tester, find.text('Wrong password. Try again.'));
    expect(find.text('Restore backup'), findsNothing);

    await tester.enterText(find.byType(TextField).last, 'long enough');
    await tester.tap(find.text('Open'));
    await settleUntil(tester, find.text('Restore backup'));
    expect(find.text(name), findsOneWidget);
  });

  testWidgets('Share… hands a copy to the share sheet and records it, '
      'unless the sheet is dismissed', (tester) async {
    // What the sheet answers: empty when dismissed.
    var answer = '';
    final shared = <String>[];
    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      final path = ((call.arguments as Map)['paths'] as List).single as String;
      // The copy is there while the sheet is open.
      if (File(path).existsSync()) shared.add(path);
      return answer;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await start(tester);
    await openBackups(tester);

    await tester.tap(find.text('Share…'));
    await settleWhen(
      tester,
      () => shared.length == 1 && !folders[1].existsSync(),
    );
    expect(shared, hasLength(1));
    expect(find.textContaining('Backup shared'), findsNothing);
    expect(await db.settingsRepository.get(SettingKeys.lastBackupAt), isNull);

    answer = 'mail';
    await tester.tap(find.text('Share…'));
    await settleUntil(tester, find.textContaining('Backup shared: '));
    expect(shared, hasLength(2));
    expect(shared.last, contains('open-sky-finance-backup-'));
    expect(
      await db.settingsRepository.get(SettingKeys.lastBackupDestination),
      'shared',
    );
    // Nothing is left where other apps could read it.
    expect(folders[1].existsSync(), isFalse);
  });

  testWidgets('Import from Bluecoins refuses what it cannot read, then '
      'replaces the data after a safety backup and goes Home', (tester) async {
    FakeFilePicker.install()
      ..pick('archive.zip', [0x50, 0x4b, 3, 4, 0, 0, 0, 0])
      ..pick('sample.fydb', bluecoinsFixture().readAsBytesSync());
    await start(tester);
    await openBackups(tester);
    Future<void> importFromBluecoins() async {
      await tester.ensureVisible(find.text('Import from Bluecoins'));
      await tester.tap(find.text('Import from Bluecoins'));
    }

    await importFromBluecoins();
    await settleUntil(tester, find.text("This file can't be imported"));
    expect(
      find.textContaining('This file is compressed (ZIP).'),
      findsOneWidget,
    );
    await tester.tap(find.text('Close'));
    await settle(tester);
    expect(await assetsAccountNames(tester), contains('Wallet'));
    expect(folders.first.existsSync(), isFalse);

    await importFromBluecoins();
    await settleUntil(tester, find.text('Replace and import'));
    expect(find.text('sample.fydb'), findsOneWidget);
    await tester.tap(find.text('Replace and import'));
    await settleUntil(tester, find.text('Bluecoins data imported'));

    expect(find.text('Bluecoins data imported'), findsOneWidget);
    final names = await assetsAccountNames(tester);
    expect(names, contains('Test Card'));
    expect(names, isNot(contains('Wallet')));
    expect(folders.first.listSync(), hasLength(1));
    // The copy that was read is gone.
    expect(folders[2].existsSync() ? folders[2].listSync() : [], isEmpty);
    expect(
      container
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .toString(),
      Routes.home,
    );
  });
}
