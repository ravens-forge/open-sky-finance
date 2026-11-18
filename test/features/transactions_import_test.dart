import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/enums/transaction_type.dart';
import 'package:open_sky_finance/data/models/transaction_draft.dart';
import 'package:open_sky_finance/data/providers.dart';
import 'package:open_sky_finance/data/repositories/setting_keys.dart';
import 'package:open_sky_finance/features/settings/providers/settings_providers.dart';
import 'package:open_sky_finance/services/backup/backup_folders.dart';

import '../data/test_db.dart';
import '../pump_app.dart';
import 'fake_file_picker.dart';

void main() {
  late ProviderContainer container;
  late AppDatabase db;
  late FakeFilePicker picker;
  late Directory safety;

  /// Settings, with a Wallet that paid the bakery.
  Future<void> start(WidgetTester tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(800, 2400);
    addTearDown(tester.view.reset);
    picker = FakeFilePicker.install();
    late List<Directory> folders;
    await tester.runAsync(() async {
      final temp = await Directory.systemTemp.createTemp('import_test');
      addTearDown(() => temp.delete(recursive: true));
      folders = [
        for (final name in ['safety_backups', 'share', 'bluecoins'])
          Directory('${temp.path}/$name'),
      ];
    });
    safety = folders.first;
    container = await pumpApp(
      tester,
      overrides: [
        backupCopyFoldersProvider.overrideWith((_) => folders),
        appVersionProvider.overrideWith((_) async => '1.2.3'),
      ],
      seed: (db) async {
        final wallet = await addAssetsAccount(db, 'Wallet');
        ok(
          await db.transactionsRepository.save(
            TransactionDraft(
              type: TransactionType.expense,
              occurredAt: DateTime(2026, 9, 17),
              amount: -m(3.2),
              assetsAccountId: wallet,
              title: 'Bakery',
            ),
          ),
        );
      },
    );
    db = container.read(appDatabaseProvider);
    container.read(routerProvider).go(Routes.settings);
    await settle(tester);
  }

  Future<void> pickToImport(WidgetTester tester, String csv) async {
    picker.pick('ledger.csv', utf8.encode(csv));
    await tester.ensureVisible(find.text('Import CSV or QIF'));
    await tester.tap(find.text('Import CSV or QIF'));
  }

  /// Titles with the assets account they landed on.
  Future<List<String>> transactions(WidgetTester tester) async => [
    for (final row in (await tester.runAsync(
      () => db
          .customSelect(
            'SELECT t.title, a.name FROM transactions t '
            'JOIN assets_accounts a ON a.id = t.assets_account_id '
            "WHERE t.title <> '' ORDER BY t.title",
          )
          .get(),
    ))!)
      '${row.read<String>('title')} @ ${row.read<String>('name')}',
  ];

  testWidgets('a CSV is previewed, added after a safety copy, and skipped '
      'the second time', (tester) async {
    const csv =
        'Date;Payee;Amount;Account;Category\n'
        '2026-09-17;Bakery;-3,20;Wallet;\n'
        '2026-09-18;Cinema;-9,00;Wallet;Leisure\n'
        '2026-09-19;Piggy bank;25,00;Savings;\n';
    await start(tester);

    await pickToImport(tester, csv);
    await settleUntil(tester, find.text('What will be added'));
    expect(find.text('ledger.csv'), findsOneWidget);
    expect(find.textContaining('CSV file · '), findsOneWidget);
    // Every row names its assets account: none to choose.
    expect(find.text('Into assets account'), findsNothing);
    expect(safety.existsSync(), isFalse);

    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await settleUntil(tester, find.text('2 transactions added'));
    expect(find.text('2 transactions added'), findsOneWidget);
    expect(
      find.textContaining('Created: 1 assets account, 1 category'),
      findsOneWidget,
    );
    // The bakery was already there.
    expect(
      find.textContaining('1 was already in the app and was skipped.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(await transactions(tester), [
      'Bakery @ Wallet',
      'Cinema @ Wallet',
      'Piggy bank @ Savings',
    ]);
    expect(safety.listSync(), hasLength(1));

    await pickToImport(tester, csv);
    await settleUntil(tester, find.text('What will be added'));
    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await settleUntil(tester, find.text('No transactions added'));
    expect(
      find.textContaining('3 were already in the app and were skipped.'),
      findsOneWidget,
    );
    expect(await transactions(tester), hasLength(3));
  });

  testWidgets('rows that name no assets account go to the chosen one', (
    tester,
  ) async {
    await start(tester);

    await pickToImport(tester, 'Date;Payee;Amount\n2026-09-18;Cinema;-9,00\n');
    await settleUntil(tester, find.text('Into assets account'));
    await tester.tap(find.text('Change').last);
    await settle(tester);
    await tester.tap(find.text('Wallet').last);
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await settleUntil(tester, find.text('1 transaction added'));

    expect(await transactions(tester), ['Bakery @ Wallet', 'Cinema @ Wallet']);
  });

  testWidgets('a file that cannot be read says why and adds nothing', (
    tester,
  ) async {
    await start(tester);

    await pickToImport(tester, 'Payee;Memo\nCinema;Friday\n');
    await settleUntil(tester, find.text("This file can't be imported"));
    expect(
      find.textContaining('needs a date column and an amount column'),
      findsOneWidget,
    );
    await tester.tap(find.text('Close'));
    await settle(tester);

    await pickToImport(tester, 'PK\u0000\u0000binary');
    await settleUntil(tester, find.text("This file can't be imported"));
    expect(
      find.textContaining('This is not a CSV or QIF file.'),
      findsOneWidget,
    );
    expect(await transactions(tester), ['Bakery @ Wallet']);
    expect(safety.existsSync(), isFalse);
  });

  testWidgets('Export to CSV saves every transaction to a file', (
    tester,
  ) async {
    await start(tester);

    await tester.ensureVisible(find.text('Export to CSV'));
    await tester.tap(find.text('Export to CSV'));
    await settle(tester);
    await tester.tap(find.text('Save to…'));
    await settleUntil(tester, find.textContaining('Exported: '));

    final name = picker.saved.keys.single;
    expect(name, startsWith('open-sky-finance-transactions-'));
    expect(name, endsWith('.csv'));
    expect(find.text('Exported: $name'), findsOneWidget);
    expect(utf8.decode(picker.saved[name]!), contains('Bakery'));
    // An export is not a backup.
    expect(await db.settingsRepository.get(SettingKeys.lastBackupAt), isNull);
  });

  testWidgets('Export to CSV shares a copy that does not outlive the sheet', (
    tester,
  ) async {
    final shared = <String>[];
    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      final path = ((call.arguments as Map)['paths'] as List).single as String;
      // The copy is there while the sheet is open.
      if (File(path).existsSync()) shared.add(path);
      return 'mail';
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await start(tester);

    await tester.ensureVisible(find.text('Export to CSV'));
    await tester.tap(find.text('Export to CSV'));
    await settle(tester);
    await tester.tap(find.text('Share…'));
    await settleUntil(tester, find.textContaining('Exported: '));

    expect(shared.single, contains('open-sky-finance-transactions-'));
    expect(File(shared.single).existsSync(), isFalse);
  });
}
