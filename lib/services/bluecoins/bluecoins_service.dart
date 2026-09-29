import 'dart:io';
import 'dart:isolate';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/ids.dart';
import '../../core/logging.dart';
import '../../core/result.dart';
import '../../data/providers.dart';
import '../../data/repositories/setting_keys.dart';
import '../../data/repositories/settings_repository.dart';
import '../backup/backup_folders.dart';
import '../backup/backup_service.dart';
import 'bluecoins_mapper.dart';
import 'bluecoins_reader.dart';
import 'models/bluecoins_import.dart';
import 'models/bluecoins_import_error.dart';
import 'models/loaded_bluecoins.dart';

part 'bluecoins_service.g.dart';

class BluecoinsService {
  BluecoinsService({required this.settings, required this.tempFolder});

  final SettingsRepository settings;

  /// Where the picked file is copied to be opened; the copy is deleted once
  /// read.
  final Directory tempFolder;

  /// Copies the picked file of [size] bytes (`null` when unknown), then reads
  /// and maps it in the background. The picked file is never opened by
  /// SQLite, so it is never changed.
  Future<Result<LoadedBluecoins, BluecoinsImportError>> load({
    required String fileName,
    required int? size,
    required Stream<List<int>> Function() read,
    required String appVersion,
    required DateTime now,
  }) async {
    if (size != null && size > BackupService.maxSize) {
      return const Err(BluecoinsFileTooLarge());
    }
    await tempFolder.create(recursive: true);
    final copy = File('${tempFolder.path}${Platform.pathSeparator}${newId()}');
    try {
      var copied = 0;
      final sink = copy.openWrite();
      try {
        await for (final chunk in read()) {
          copied += chunk.length;
          if (copied > BackupService.maxSize) {
            return const Err(BluecoinsFileTooLarge());
          }
          sink.add(chunk);
        }
      } finally {
        await sink.close();
      }

      final kept = {
        for (final key in SettingKeys.backedUp) key: ?await settings.get(key),
      };
      final path = copy.path;
      final mapped = await Isolate.run(
        () => switch (BluecoinsReader.read(path)) {
          Ok(:final value) => Ok<BluecoinsImport, BluecoinsImportError>(
            BluecoinsMapper.map(
              value,
              now: now,
              appVersion: appVersion,
              settings: kept,
            ),
          ),
          Err(:final error) => Err<BluecoinsImport, BluecoinsImportError>(
            error,
          ),
        },
      );
      switch (mapped) {
        case Err(:final error):
          return Err(error);
        case Ok(value: final import):
          final report = import.report;
          Log.count('bluecoins.userVersion', report.userVersion);
          for (final MapEntry(:key, :value) in report.skipped.entries) {
            Log.count('bluecoins.skipped.${key.name}', value);
          }
          return Ok(
            LoadedBluecoins(fileName: fileName, size: copied, import: import),
          );
      }
    } on IOException catch (error, stackTrace) {
      Log.error(error, stackTrace);
      return const Err(BluecoinsImportFailed());
    } finally {
      if (await copy.exists()) await copy.delete();
    }
  }
}

@Riverpod(keepAlive: true)
Future<BluecoinsService> bluecoinsService(Ref ref) async {
  final folders = await ref.watch(backupCopyFoldersProvider.future);
  return BluecoinsService(
    settings: ref.watch(settingsRepositoryProvider),
    tempFolder: folders[2],
  );
}
