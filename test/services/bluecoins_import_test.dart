import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/core/result.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/enums/assets_account_type.dart';
import 'package:open_sky_finance/data/enums/category_kind.dart';
import 'package:open_sky_finance/data/enums/transaction_type.dart';
import 'package:open_sky_finance/data/repositories/setting_keys.dart';
import 'package:open_sky_finance/services/backup/backup_service.dart';
import 'package:open_sky_finance/services/bluecoins/bluecoins_mapper.dart';
import 'package:open_sky_finance/services/bluecoins/bluecoins_reader.dart';
import 'package:open_sky_finance/services/bluecoins/bluecoins_service.dart';
import 'package:open_sky_finance/services/bluecoins/models/bluecoins_import.dart';
import 'package:open_sky_finance/services/bluecoins/models/bluecoins_import_error.dart';
import 'package:open_sky_finance/services/bluecoins/models/bluecoins_note.dart';
import 'package:open_sky_finance/services/bluecoins/models/bluecoins_skip_reason.dart';
import 'package:open_sky_finance/services/bluecoins/models/bluecoins_tables.dart';
import 'package:open_sky_finance/services/bluecoins/models/loaded_bluecoins.dart';
import 'package:sqlite3/sqlite3.dart';

import '../data/test_db.dart';
import 'bluecoins_fixture.dart';

/// "Now" in these tests: the sample data has one expense after it.
final _now = DateTime(2026, 9, 17, 10, 30);
final _tomorrow = DateTime(2026, 9, 18);

BluecoinsTables _read(File file) => switch (BluecoinsReader.read(file.path)) {
  Ok(:final value) => value,
  Err(:final error) => throw StateError('expected Ok, got $error'),
};

BluecoinsImportError? _error(File file) =>
    switch (BluecoinsReader.read(file.path)) {
      Ok() => null,
      Err(:final error) => error,
    };

BluecoinsImport _map(File file) =>
    BluecoinsMapper.map(_read(file), now: _now, appVersion: '1.0.0');

(BluecoinsService, Directory) _service(AppDatabase db) {
  final dir = Directory.systemTemp.createTempSync('bluecoins_service');
  addTearDown(() => dir.deleteSync(recursive: true));
  return (
    BluecoinsService(
      settings: db.settingsRepository,
      tempFolder: Directory('${dir.path}/import'),
    ),
    dir,
  );
}

Future<Result<LoadedBluecoins, BluecoinsImportError>> _load(
  BluecoinsService service,
  File file,
) => service.load(
  fileName: 'sample.fydb',
  size: file.lengthSync(),
  read: file.openRead,
  appVersion: '1.0.0',
  now: _now,
);

File _file(List<int> bytes) {
  final dir = Directory.systemTemp.createTempSync('bluecoins_bytes');
  addTearDown(() => dir.deleteSync(recursive: true));
  return File('${dir.path}/file.fydb')..writeAsBytesSync(bytes);
}

/// Source rows of the sample data that the importer reports as skipped
/// although they are active: a transfer leg without its pair (43) and an
/// expense in pounds on a euro assets account (45).
const _skippedActive = [43, 45];

void main() {
  group('reader', () {
    test('reads the sample backup and its version', () {
      final tables = _read(bluecoinsFixture());
      expect(tables.userVersion, 47);
      expect(tables.accounts, hasLength(8));
      expect(tables.transactions, hasLength(25));
      expect(tables.labels, hasLength(7));
    });

    test('rejects ZIP files and files that are not SQLite', () {
      expect(
        _error(_file([0x50, 0x4B, 0x03, 0x04, ...List.filled(40, 0)])),
        isA<BluecoinsCompressed>(),
      );
      expect(
        _error(_file('{"format":"open-sky-finance-backup"}'.codeUnits)),
        isA<BluecoinsNotABackup>(),
      );
      expect(_error(_file(const [])), isA<BluecoinsNotABackup>());
    });

    test('rejects SQLite files without the Bluecoins tables', () {
      final dir = Directory.systemTemp.createTempSync('bluecoins_other');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = '${dir.path}/other.db';
      sqlite3.open(path)
        ..execute('CREATE TABLE notes (id INTEGER PRIMARY KEY, text TEXT)')
        ..close();
      expect(_error(File(path)), isA<BluecoinsNotABackup>());
    });

    test('lists the missing columns', () {
      final file = bluecoinsFixture(
        sample: false,
        extra:
            'ALTER TABLE TRANSACTIONSTABLE DROP COLUMN notes;'
            'ALTER TABLE LABELSTABLE DROP COLUMN labelName;',
      );
      final error = _error(file);
      expect(error, isA<BluecoinsMissingColumns>());
      expect((error! as BluecoinsMissingColumns).columns, [
        'TRANSACTIONSTABLE.notes',
        'LABELSTABLE.labelName',
      ]);
    });

    test('optional tables may be missing', () {
      final tables = _read(
        bluecoinsFixture(
          sample: false,
          extra: 'DROP TABLE LABELSTABLE; DROP TABLE SETTINGSTABLE;',
        ),
      );
      expect(tables.labels, isEmpty);
      expect(tables.settings, isEmpty);
    });

    test('reports damaged files', () {
      final bytes = bluecoinsFixture().readAsBytesSync();
      // Keep the header, scramble every page after the first.
      for (var i = 4096; i < bytes.length; i++) {
        bytes[i] = (bytes[i] * 31 + 7) & 0xFF;
      }
      expect(_error(_file(bytes)), isA<BluecoinsDamaged>());
    });
  });

  group('mapper', () {
    test('imports assets accounts by type id, skipping placeholders', () {
      final accounts = {
        for (final a in _map(bluecoinsFixture()).snapshot.assetsAccounts)
          a.name: a,
      };
      expect(accounts.keys, [
        'Test Bank',
        'Test Wallet',
        'Test Card',
        'Old Savings',
        'Test Dollars',
        'Custom Debt',
      ]);
      expect(accounts['Test Bank']!.type, AssetsAccountType.bank);
      expect(accounts['Test Wallet']!.type, AssetsAccountType.cash);
      expect(accounts['Test Card']!.type, AssetsAccountType.creditCard);
      expect(accounts['Test Card']!.creditLimit, m(1500));
      expect(accounts['Test Bank']!.creditLimit, isNull);
      expect(accounts['Old Savings']!.isHidden, isTrue);
      expect(accounts['Test Dollars']!.currency, 'USD');
      // Type 17 is unknown; its accounting group says liability.
      expect(accounts['Custom Debt']!.type, AssetsAccountType.otherLiability);
    });

    test('parents become groups and children categories', () {
      final snapshot = _map(bluecoinsFixture()).snapshot;
      final groups = {for (final g in snapshot.categoryGroups) g.id: g};
      expect(
        [for (final g in snapshot.categoryGroups) (g.name, g.kind)],
        [
          ('Salary', CategoryKind.income),
          ('Food', CategoryKind.expense),
          ('Other', CategoryKind.expense),
          ('Other', CategoryKind.income),
        ],
      );
      expect(
        [
          for (final c in snapshot.categories)
            (c.name, groups[c.groupId]!.name, c.icon),
        ],
        [
          ('Monthly pay', 'Salary', 'work'),
          ('Groceries', 'Food', 'local_grocery_store'),
          ('Fuel', 'Other', 'local_gas_station'),
          ('Misc', 'Other', 'category'),
          ('Gifts', 'Other', 'card_giftcard'),
        ],
      );
      expect(
        snapshot.categories.map((c) => c.budgetAmount),
        everyElement(null),
      );
      expect(
        snapshot.categoryGroups.map((g) => g.budgetAmount),
        everyElement(null),
      );
    });

    test('converts icon names', () {
      expect(
        BluecoinsMapper.icon('Outlined.LocalGasStation'),
        'local_gas_station',
      );
      expect(BluecoinsMapper.icon('Filled.Home'), 'home');
      expect(BluecoinsMapper.icon('AutoMirrored.Outlined.List'), 'category');
      expect(BluecoinsMapper.icon(null), 'category');
    });

    test('reports what was skipped or changed, counts only', () {
      final report = _map(bluecoinsFixture()).report;
      expect(report.userVersion, 47);
      expect(report.skipped, {
        BluecoinsSkipReason.budget: 2,
        BluecoinsSkipReason.deleted: 3,
        BluecoinsSkipReason.reminder: 1,
        BluecoinsSkipReason.unknownType: 2,
        BluecoinsSkipReason.otherCurrency: 1,
        BluecoinsSkipReason.missingAssetsAccount: 1,
        BluecoinsSkipReason.orphanTransfer: 1,
      });
      expect(report.skippedTotal, 11);
      expect(report.notes, {
        BluecoinsNote.unknownAssetsAccountType: 1,
        BluecoinsNote.uncategorized: 1,
        BluecoinsNote.splitTransaction: 1,
      });
    });

    test('maps transaction types, titles and categories', () {
      final snapshot = _map(bluecoinsFixture()).snapshot;
      final categories = {for (final c in snapshot.categories) c.id: c.name};
      final byTitle = {for (final t in snapshot.transactions) t.title: t};
      final shop = byTitle['Supermarket']!;
      expect(shop.type, TransactionType.expense);
      expect(shop.amount, -m(45.5));
      expect(shop.occurredAt, DateTime(2026, 1, 5, 12, 30));
      expect(shop.notes, 'Weekly shop');
      expect(categories[shop.categoryId], 'Groceries');
      final refund = byTitle['Refund']!;
      expect((refund.type, refund.amount), (TransactionType.expense, m(10)));
      expect(byTitle['Salary']!.type, TransactionType.income);
      expect(byTitle['Kiosk']!.categoryId, isNull);
      // The zero opening balance is left out.
      final openings = snapshot.transactions.where(
        (t) => t.type == TransactionType.openingBalance,
      );
      expect(openings.map((t) => t.amount), [m(1000), -m(200), m(500), -m(50)]);
      expect(openings.map((t) => t.categoryId), everyElement(null));
    });

    test('merges transfer legs', () {
      final snapshot = _map(bluecoinsFixture()).snapshot;
      final names = {for (final a in snapshot.assetsAccounts) a.id: a.name};
      final transfers = [
        for (final t in snapshot.transactions)
          if (t.type == TransactionType.transfer) t,
      ];
      expect(
        [
          for (final t in transfers)
            (
              names[t.assetsAccountId],
              names[t.toAssetsAccountId],
              t.amount,
              t.toAmount,
              t.currency,
            ),
        ],
        [
          ('Test Bank', 'Test Wallet', m(100), null, 'EUR'),
          ('Test Bank', 'Test Dollars', m(90), m(100), 'EUR'),
        ],
      );
      expect(transfers.first.title, 'To the wallet');
      expect(transfers.first.notes, 'Cash for the week');
    });

    test('pairs legs without a group by their ids', () {
      final snapshot = BluecoinsMapper.map(
        _read(
          bluecoinsFixture(
            extra:
                'UPDATE TRANSACTIONSTABLE SET transferGroupID = NULL, '
                'accountReference = NULL WHERE transactionsTableID IN (30, 31)',
          ),
        ),
        now: _now,
        appVersion: '1.0.0',
      ).snapshot;
      expect(
        snapshot.transactions.where((t) => t.type == TransactionType.transfer),
        hasLength(2),
      );
    });

    test('labels are deduplicated and follow merged transfers', () {
      final snapshot = _map(bluecoinsFixture()).snapshot;
      expect(snapshot.labels.map((l) => l.name), [
        'Holiday',
        'Trip',
        'Weekly',
        'Car',
        'Gone',
      ]);
      final labels = {for (final l in snapshot.labels) l.id: l.name};
      final titles = {for (final t in snapshot.transactions) t.id: t.title};
      expect(
        [
          for (final a in snapshot.transactionLabels)
            (titles[a.transactionId], labels[a.labelId]),
        ],
        [
          ('Supermarket', 'Holiday'),
          ('To the wallet', 'Weekly'),
          ('Gas station', 'Car'),
        ],
      );
    });

    test('sets only the main currency and keeps the other settings', () {
      final snapshot = BluecoinsMapper.map(
        _read(bluecoinsFixture()),
        now: _now,
        appVersion: '1.0.0',
        settings: {SettingKeys.mainCurrency: 'USD', SettingKeys.locale: 'fr'},
      ).snapshot;
      expect(snapshot.settings, {
        SettingKeys.mainCurrency: 'EUR',
        SettingKeys.locale: 'fr',
      });
    });
  });

  group('service', () {
    test('reads a copy, deletes it and leaves the file untouched', () async {
      final db = testDb();
      final (service, dir) = _service(db);
      final file = bluecoinsFixture();
      final before = file.readAsBytesSync();
      final loaded = await _load(service, file);
      expect(loaded, isA<Ok<LoadedBluecoins, BluecoinsImportError>>());
      expect(
        (loaded as Ok<LoadedBluecoins, BluecoinsImportError>).value.size,
        before.length,
      );
      expect(file.readAsBytesSync(), before);
      expect(Directory('${dir.path}/import').listSync(), isEmpty);
    });

    test('deletes the copy when the file is rejected', () async {
      final db = testDb();
      final (service, dir) = _service(db);
      final loaded = await _load(service, _file('not a database'.codeUnits));
      expect((loaded as Err).error, isA<BluecoinsNotABackup>());
      expect(Directory('${dir.path}/import').listSync(), isEmpty);
    });

    test('rejects files over the size limit before copying', () async {
      final db = testDb();
      final (service, _) = _service(db);
      final loaded = await service.load(
        fileName: 'big.fydb',
        size: BackupService.maxSize + 1,
        read: () => throw StateError('read'),
        appVersion: '1.0.0',
        now: _now,
      );
      expect((loaded as Err).error, isA<BluecoinsFileTooLarge>());
    });
  });

  group('validation checklist', () {
    /// Imports the sample through the restore write path.
    Future<(AppDatabase, BluecoinsImport)> importSample() async {
      final db = testDb();
      final (service, dir) = _service(db);
      final loaded = await _load(service, bluecoinsFixture());
      final import =
          (loaded as Ok<LoadedBluecoins, BluecoinsImportError>).value.import;
      final backups = BackupService(
        backups: db.backupRepository,
        settings: db.settingsRepository,
        safetyFolder: Directory('${dir.path}/safety'),
        shareFolder: Directory('${dir.path}/share'),
      );
      expect(
        await backups.restore(import.snapshot, appVersion: '1.0.0'),
        isA<Ok<void, Object>>(),
      );
      return (db, import);
    }

    Future<Map<String, int>> balancesByName(AppDatabase db) async {
      final balances = await db.balancesRepository
          .watchBalances(_tomorrow)
          .first;
      final accounts = await db.select(db.assetsAccountsTable).get();
      return {for (final a in accounts) a.name: balances[a.id]!};
    }

    test('balance per assets account equals the source rows', () async {
      final (db, import) = await importSample();
      final source = sqlite3.open(bluecoinsFixture().path);
      addTearDown(source.close);
      final expected = {
        for (final row in source.select('''
SELECT a.accountName AS name, COALESCE(SUM(t.amount), 0) AS total
FROM ACCOUNTSTABLE a
LEFT JOIN TRANSACTIONSTABLE t ON t.accountID = a.accountsTableID
  AND t.deletedTransaction = 6 AND t.reminderTransaction IS NULL
  AND t.transactionTypeID IN (1, 2, 3, 4, 5)
  AND t.date <= '2026-09-17 23:59:59'
  AND t.transactionsTableID NOT IN (${_skippedActive.join(', ')})
WHERE a.accountTypeID <> 0
GROUP BY a.accountsTableID'''))
          (row['name'] as String).trim(): row['total'] as int,
      };
      expect(await balancesByName(db), expected);
      expect(expected, {
        'Test Bank': m(2774.5),
        'Test Wallet': m(87),
        'Test Card': -m(280),
        'Old Savings': m(500),
        'Test Dollars': m(100),
        'Custom Debt': -m(50),
      });
      // The preview's balances are the same sums.
      final names = {
        for (final a in import.snapshot.assetsAccounts) a.id: a.name,
      };
      expect({
        for (final MapEntry(:key, :value)
            in import.snapshot.balances(_tomorrow).entries)
          names[key]!: value,
      }, expected);
    });

    test('transaction count: kept rows plus one per transfer', () async {
      final (db, _) = await importSample();
      final source = sqlite3.open(bluecoinsFixture().path);
      addTearDown(source.close);
      final kept =
          source.select(
                '''
SELECT COUNT(*) AS n FROM TRANSACTIONSTABLE
WHERE deletedTransaction = 6 AND reminderTransaction IS NULL
  AND transactionTypeID IN (1, 2, 3, 4) AND accountID NOT IN (-1, 0)
  AND amount <> 0 AND transactionsTableID NOT IN (${_skippedActive.join(', ')})''',
              ).single['n']
              as int;
      final transfers =
          source
                  .select(
                    'SELECT COUNT(DISTINCT transferGroupID) AS n FROM TRANSACTIONSTABLE '
                    'WHERE transactionTypeID = 5 AND deletedTransaction = 6 '
                    'AND transactionsTableID NOT IN (${_skippedActive.join(', ')})',
                  )
                  .single['n']
              as int;
      final rows = await db.select(db.transactionsTable).get();
      expect(rows, hasLength(kept + transfers));
      expect(rows, hasLength(13));
    });

    test('nothing points at a skipped assets account or category', () async {
      final (db, _) = await importSample();
      Future<int> count(String sql) async =>
          (await db.customSelect(sql).getSingle()).read<int>('n');
      expect(
        await count(
          'SELECT COUNT(*) AS n FROM transactions t WHERE NOT EXISTS '
          '(SELECT 1 FROM assets_accounts a WHERE a.id = t.assets_account_id) '
          'OR (t.to_assets_account_id IS NOT NULL AND NOT EXISTS '
          '(SELECT 1 FROM assets_accounts a WHERE a.id = t.to_assets_account_id))',
        ),
        0,
      );
      expect(
        await count(
          'SELECT COUNT(*) AS n FROM transactions t WHERE t.category_id IS NOT '
          'NULL AND NOT EXISTS (SELECT 1 FROM categories c WHERE c.id = t.category_id)',
        ),
        0,
      );
      expect(
        await count(
          'SELECT COUNT(*) AS n FROM transaction_labels l WHERE NOT EXISTS '
          '(SELECT 1 FROM transactions t WHERE t.id = l.transaction_id)',
        ),
        0,
      );
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    });

    test('importing the same file again gives the same balances', () async {
      final (db, _) = await importSample();
      final first = await balancesByName(db);
      final dir = Directory.systemTemp.createTempSync('bluecoins_again');
      addTearDown(() => dir.deleteSync(recursive: true));
      final again =
          await BluecoinsService(
            settings: db.settingsRepository,
            tempFolder: dir,
          ).load(
            fileName: 'sample.fydb',
            size: null,
            read: bluecoinsFixture().openRead,
            appVersion: '1.0.0',
            now: _now,
          );
      await BackupService(
        backups: db.backupRepository,
        settings: db.settingsRepository,
        safetyFolder: Directory('${dir.path}/safety'),
        shareFolder: Directory('${dir.path}/share'),
      ).restore(
        (again as Ok<LoadedBluecoins, BluecoinsImportError>)
            .value
            .import
            .snapshot,
        appVersion: '1.0.0',
      );
      expect(await balancesByName(db), first);
      expect(await db.settingsRepository.get(SettingKeys.mainCurrency), 'EUR');
      // The replaced data went to a safety backup first.
      expect(Directory('${dir.path}/safety').listSync(), hasLength(1));
    });
  });
}
