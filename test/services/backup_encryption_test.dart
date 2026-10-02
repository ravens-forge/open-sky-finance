import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/core/result.dart';
import 'package:open_sky_finance/data/repositories/setting_keys.dart';
import 'package:open_sky_finance/services/backup/backup_codec.dart';
import 'package:open_sky_finance/services/backup/backup_encryption.dart';
import 'package:open_sky_finance/services/backup/backup_service.dart';
import 'package:open_sky_finance/services/backup/models/backup_kdf.dart';
import 'package:open_sky_finance/services/backup/models/loaded_backup.dart';
import 'package:open_sky_finance/services/backup/models/restore_error.dart';

import '../data/test_db.dart';

/// Cheap Argon2id costs: the real ones take about a second per key.
const _kdf = BackupKdf(memoryKiB: 64, iterations: 1);

void main() {
  test('round trip: the right password opens, a wrong one does not', () async {
    final key = await BackupEncryption.deriveKey('correct horse', kdf: _kdf);
    final plain = utf8.encode('{"format":"open-sky-finance-backup"}');
    final bytes = await BackupEncryption.encrypt(plain, key);

    final json = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
    expect(json['format'], BackupEncryption.format);
    expect(utf8.decode(bytes), isNot(contains('open-sky-finance-backup"')));
    final file = BackupEncryption.read(json)!;
    expect(file.kdf.memoryKiB, 64);

    expect(await BackupEncryption.decrypt(file, 'correct horse'), plain);
    expect(await BackupEncryption.decrypt(file, 'wrong horse'), isNull);
  });

  test('every file gets its own nonce', () async {
    final key = await BackupEncryption.deriveKey('password', kdf: _kdf);
    String nonce(List<int> bytes) =>
        ((jsonDecode(utf8.decode(bytes)) as Map)['cipher'] as Map)['nonce']
            as String;
    final a = await BackupEncryption.encrypt([1, 2, 3], key);
    final b = await BackupEncryption.encrypt([1, 2, 3], key);
    expect(nonce(a), isNot(nonce(b)));
  });

  test('a changed file is refused, not decrypted', () async {
    final key = await BackupEncryption.deriveKey('password', kdf: _kdf);
    final json = jsonDecode(
      utf8.decode(await BackupEncryption.encrypt([1, 2, 3, 4], key)),
    ) as Map<String, Object?>;
    final payload = base64.decode(json['payload']! as String)..[0] ^= 1;
    json['payload'] = base64.encode(payload);
    final file = BackupEncryption.read(json)!;
    expect(await BackupEncryption.decrypt(file, 'password'), isNull);
  });

  test('the codec asks for the password of an encrypted file', () async {
    final key = await BackupEncryption.deriveKey('password', kdf: _kdf);
    final bytes = await BackupEncryption.encrypt([1], key);
    expect(BackupCodec.decode(bytes), isA<Err<Object, RestoreError>>());
    expect(
      (BackupCodec.decode(bytes) as Err).error,
      isA<RestoreNeedsPassword>(),
    );
  });

  test('backups made with a password restore with it only', () async {
    final db = testDb();
    final dir = Directory.systemTemp.createTempSync('encrypted_backup');
    addTearDown(() => dir.deleteSync(recursive: true));
    final service = BackupService(
      backups: db.backupRepository,
      settings: db.settingsRepository,
      safetyFolder: Directory('${dir.path}/safety'),
      shareFolder: Directory('${dir.path}/share'),
    );
    await addAssetsAccount(db, 'Bank');
    await service.setPassword('long password', kdf: _kdf);
    // Only the derived key is kept.
    final stored = await db.settingsRepository.get(SettingKeys.backupKey);
    expect(stored, isNot(contains('long password')));

    final file = await service.export(appVersion: '1.0.0');
    final loaded = await service.load(
      fileName: file.name,
      size: file.bytes.length,
      read: () async => file.bytes,
    );
    final locked = ((loaded as Err).error as RestoreNeedsPassword).file;

    final wrong = await service.unlock(
      fileName: file.name,
      size: file.bytes.length,
      file: locked,
      password: 'other password',
    );
    expect((wrong as Err).error, isA<RestoreWrongPassword>());

    final opened = await service.unlock(
      fileName: file.name,
      size: file.bytes.length,
      file: locked,
      password: 'long password',
    );
    final backup = (opened as Ok<LoadedBackup, RestoreError>).value;
    expect(backup.snapshot.assetsAccounts.single.name, 'Bank');

    // Safety backups stay in the private folder, never encrypted.
    await service.restore(backup.snapshot, appVersion: '1.0.0');
    final safety = Directory('${dir.path}/safety').listSync().single as File;
    expect(
      BackupCodec.decode(safety.readAsBytesSync()),
      isA<Ok<Object?, Object?>>(),
    );

    await service.setPassword(null);
    final plain = await service.export(appVersion: '1.0.0');
    expect(BackupCodec.decode(plain.bytes), isA<Ok<Object?, Object?>>());
  });
}
