import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/core/result.dart';
import 'package:open_sky_finance/data/enums/transaction_type.dart';
import 'package:open_sky_finance/data/models/app_snapshot.dart';
import 'package:open_sky_finance/data/models/transaction_draft.dart';
import 'package:open_sky_finance/data/repositories/setting_keys.dart';
import 'package:open_sky_finance/services/backup/backup_codec.dart';
import 'package:open_sky_finance/services/backup/models/backup_problem.dart';
import 'package:open_sky_finance/services/backup/models/backup_problem_code.dart';
import 'package:open_sky_finance/services/backup/models/restore_error.dart';

import '../data/test_db.dart';

final _fixture = File('test/fixtures/backup/v1_sample.json');

Map<String, Object?> _sample() =>
    jsonDecode(_fixture.readAsStringSync()) as Map<String, Object?>;

Result<AppSnapshot, RestoreError> _decode(Object? json) =>
    BackupCodec.decode(utf8.encode(jsonEncode(json)));

AppSnapshot _ok(Result<AppSnapshot, RestoreError> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final error) => throw StateError('expected Ok, got $error'),
};

List<BackupProblem> _problems(Result<AppSnapshot, RestoreError> result) =>
    switch (result) {
      Err(error: RestoreInvalid(:final problems)) => problems,
      _ => throw StateError('expected RestoreInvalid, got $result'),
    };

Map<String, Object?> _data(Map<String, Object?> json) =>
    json['data']! as Map<String, Object?>;

Map<String, Object?> _item(Map<String, Object?> json, String list, int i) =>
    (_data(json)[list]! as List<Object?>)[i]! as Map<String, Object?>;

/// Writes [snapshot] into a fresh database and reads it back.
Future<AppSnapshot> _throughDb(AppSnapshot snapshot) async {
  final db = testDb();
  await db.backupRepository.replaceAll(snapshot);
  return db.backupRepository.snapshot(
    appVersion: snapshot.appVersion,
    exportedAt: snapshot.exportedAt,
  );
}

void main() {
  test('the v1 fixture restores and exports again unchanged', () async {
    final snapshot = _ok(BackupCodec.decode(_fixture.readAsBytesSync()));
    expect(snapshot.counts.transactions, 5);
    expect(snapshot.counts.trashed, 1);
    expect(snapshot.counts.budgets, 2);
    final again = BackupCodec.encode(await _throughDb(snapshot));
    expect(jsonDecode(utf8.decode(again)), _sample());
  });

  test('encodes with 2-space indentation', () {
    final text = utf8.decode(
      BackupCodec.encode(_ok(BackupCodec.decode(_fixture.readAsBytesSync()))),
    );
    expect(text, startsWith('{\n  "format": "open-sky-finance-backup",\n'));
  });

  test('a database round-trips through a backup', () async {
    final db = testDb();
    final bank = await addAssetsAccount(db, 'Bank', openingBalance: m(100));
    final usd = await addAssetsAccount(db, 'Dollars', currency: 'USD');
    final group = await addCategoryGroup(db, 'Food');
    final category = await addCategory(db, 'Groceries', groupId: group);
    ok(await db.budgetsRepository.set(category, m(300)));
    final label = ok(await db.labelsRepository.save(name: 'Trip'));
    ok(
      await db.transactionsRepository.save(
        TransactionDraft(
          type: TransactionType.expense,
          occurredAt: DateTime(2026, 9, 1, 18, 30),
          amount: -m(12.5),
          assetsAccountId: bank,
          categoryId: category,
          title: 'Market',
          labelIds: [label],
        ),
      ),
    );
    final moved = ok(
      await db.transactionsRepository.save(
        TransactionDraft(
          type: TransactionType.transfer,
          occurredAt: DateTime(2026, 9, 2),
          amount: m(50),
          assetsAccountId: bank,
          toAssetsAccountId: usd,
          toAmount: m(54.7),
        ),
      ),
    );
    await db.transactionsRepository.trash(moved);
    await addReminder(db, 'r1', assetsAccountId: bank, categoryId: category);
    await db.settingsRepository.set(SettingKeys.locale, 'fr');

    final before = await db.backupRepository.snapshot(
      appVersion: '1.0.0',
      exportedAt: DateTime.utc(2026, 9, 17),
    );
    final json = BackupCodec.encode(before);
    final after = await _throughDb(_ok(BackupCodec.decode(json)));
    expect(utf8.decode(BackupCodec.encode(after)), utf8.decode(json));
    expect(after.settings[SettingKeys.locale], 'fr');
  });

  test('omitted optional fields take their defaults', () {
    final json = _sample();
    _data(json).remove('reminders');
    final transaction = _item(json, 'transactions', 6)
      ..removeWhere(
        (key, _) => ['labelIds', 'reminderId', 'deletedAt'].contains(key),
      )
      ..remove('toAssetsAccountId')
      ..remove('toAmount')
      ..remove('exchangeRate');
    // The reminder it pointed at is gone with the collection.
    _item(json, 'transactions', 2).remove('reminderId');
    final snapshot = _ok(_decode(json));
    expect(transaction['id'], snapshot.transactions[6].id);
    expect(snapshot.reminders, isEmpty);
    expect(snapshot.transactions[6].deletedAt, isNull);
  });

  test('unknown settings fall back instead of failing', () {
    final json = _sample();
    (_data(json)['settings']! as Map<String, Object?>)
      ..['locale'] = 'de'
      ..['homeSections'] = [
        {'id': 'someday', 'visible': true},
        {'id': 'netWorth', 'visible': false},
      ]
      ..['futureSetting'] = 1;
    final snapshot = _ok(_decode(json));
    expect(snapshot.settings.containsKey(SettingKeys.locale), isFalse);
    expect(
      snapshot.settings[SettingKeys.homeSections],
      startsWith('[{"id":"netWorth","visible":false},'),
    );
  });

  test('collects every problem before failing', () {
    final json = _sample();
    _item(json, 'assetsAccounts', 1)['id'] = _item(
      json,
      'assetsAccounts',
      0,
    )['id'];
    _item(json, 'assetsAccounts', 2)['type'] = 'boat';
    _item(json, 'categories', 2).remove('groupId');
    _item(json, 'labels', 1)['name'] = 'HOME';
    _item(json, 'transactions', 3)['amount'] = '12.50';
    _item(json, 'transactions', 4)['toAssetsAccountId'] = _item(
      json,
      'transactions',
      4,
    )['assetsAccountId'];
    _item(json, 'transactions', 5)['toAmount'] = null;
    _item(json, 'transactions', 6)['categoryId'] =
        '00000000-0000-4000-8000-000000000c01';
    _item(json, 'transactions', 7)['occurredAt'] = '2026-09-06T12:00:00Z';
    expect(
      _problems(_decode(json)),
      containsAll([
        const BackupProblem(
          BackupProblemCode.duplicateId,
          'data.assetsAccounts[1].id',
        ),
        const BackupProblem(
          BackupProblemCode.invalidValue,
          'data.assetsAccounts[2].type',
        ),
        const BackupProblem(
          BackupProblemCode.missing,
          'data.categories[2].groupId',
        ),
        const BackupProblem(
          BackupProblemCode.duplicateName,
          'data.labels[1].name',
        ),
        const BackupProblem(
          BackupProblemCode.wrongType,
          'data.transactions[3].amount',
        ),
        const BackupProblem(
          BackupProblemCode.brokenRule,
          'data.transactions[4].toAssetsAccountId',
        ),
        const BackupProblem(
          BackupProblemCode.brokenRule,
          'data.transactions[5].toAmount',
        ),
        const BackupProblem(
          BackupProblemCode.brokenRule,
          'data.transactions[6].categoryId',
        ),
        const BackupProblem(
          BackupProblemCode.invalidValue,
          'data.transactions[7].occurredAt',
        ),
      ]),
    );
  });

  test('references must point inside the file', () {
    final json = _sample();
    _item(json, 'transactions', 2)
      ..['reminderId'] = 'gone'
      ..['labelIds'] = ['gone'];
    _item(json, 'transactions', 3)['assetsAccountId'] = 'gone';
    expect(
      _problems(_decode(json)),
      containsAll([
        const BackupProblem(
          BackupProblemCode.unknownReference,
          'data.transactions[2].reminderId',
        ),
        const BackupProblem(
          BackupProblemCode.unknownReference,
          'data.transactions[2].labelIds[0]',
        ),
        const BackupProblem(
          BackupProblemCode.unknownReference,
          'data.transactions[3].assetsAccountId',
        ),
      ]),
    );
  });

  test('budgets only on spending, amounts in the account currency', () {
    final json = _sample();
    _item(json, 'categoryGroups', 0)['budget'] = {
      'amount': 1000000,
      'period': 'monthly',
      'rollover': false,
    };
    _item(json, 'transactions', 3)['currency'] = 'USD';
    expect(
      _problems(_decode(json)),
      containsAll([
        const BackupProblem(
          BackupProblemCode.brokenRule,
          'data.categoryGroups[0].budget',
        ),
        const BackupProblem(
          BackupProblemCode.brokenRule,
          'data.transactions[3].currency',
        ),
      ]),
    );
  });

  test('rejects what is not a backup', () {
    for (final bytes in [
      utf8.encode('not json'),
      utf8.encode('[]'),
      utf8.encode('{"format": "something-else", "schemaVersion": 1}'),
      [0xFF, 0xFE, 0x00],
    ]) {
      expect(
        BackupCodec.decode(bytes),
        isA<Err<AppSnapshot, RestoreError>>().having(
          (e) => e.error,
          'error',
          isA<RestoreNotABackup>(),
        ),
      );
    }
  });

  test('rejects a newer schemaVersion', () {
    final json = _sample()..['schemaVersion'] = 2;
    expect(
      _decode(json),
      isA<Err<AppSnapshot, RestoreError>>().having(
        (e) => e.error,
        'error',
        isA<RestoreNewerVersion>(),
      ),
    );
  });

  test('reads a file with a byte order mark', () {
    _ok(BackupCodec.decode([0xEF, 0xBB, 0xBF, ..._fixture.readAsBytesSync()]));
  });

  test('keeps the first problems and counts them all', () {
    final json = _sample();
    _data(json)['labels'] = [
      for (var i = 0; i < 150; i++) {'id': 'l$i'},
    ];
    final result = _decode(json);
    expect(
      result,
      isA<Err<AppSnapshot, RestoreError>>().having(
        (e) => e.error,
        'error',
        isA<RestoreInvalid>()
            .having((e) => e.problems.length, 'kept', 100)
            .having((e) => e.total, 'total', greaterThanOrEqualTo(150)),
      ),
    );
  });

  test('a restore replaces everything but the device settings', () async {
    final db = testDb();
    await addAssetsAccount(db, 'Old');
    for (final (key, value) in [
      (SettingKeys.locale, 'es'),
      (SettingKeys.onboardingSeenSteps, '["welcome"]'),
      (SettingKeys.lastBackupAt, '2026-09-10T08:00:00Z'),
    ]) {
      await db.settingsRepository.set(key, value);
    }
    await db.backupRepository.replaceAll(
      _ok(BackupCodec.decode(_fixture.readAsBytesSync())),
    );
    final names = await db.select(db.assetsAccountsTable).map((a) => a.name).get();
    expect(names, isNot(contains('Old')));
    expect(await db.settingsRepository.get(SettingKeys.locale), isNull);
    expect(
      await db.settingsRepository.get(SettingKeys.onboardingSeenSteps),
      '["welcome"]',
    );
    expect(
      await db.settingsRepository.get(SettingKeys.lastBackupAt),
      '2026-09-10T08:00:00Z',
    );
  });
}
