import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/now.dart';
import '../../../core/logging.dart';
import '../../../core/result.dart';
import '../../../data/models/app_snapshot.dart';
import '../../../data/providers.dart';
import '../../../services/backup/backup_service.dart';
import '../../../services/backup/models/backup_destination.dart';
import '../../../services/backup/models/encrypted_backup.dart';
import '../../../services/backup/models/loaded_backup.dart';
import '../../../services/backup/models/restore_error.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../settings/providers/settings_providers.dart';
import '../models/restore_preview.dart';

part 'backup_controller.g.dart';

@Riverpod(keepAlive: true)
class BackupController extends _$BackupController {
  @override
  void build() {}

  Future<BackupService> get _service => ref.read(backupServiceProvider.future);

  Future<String> get _appVersion => ref.read(appVersionProvider.future);

  /// Save to…: the system save dialog, where installed cloud providers show
  /// up too. The file name once saved, `null` when cancelled.
  Future<Result<String?, AppError>> saveTo() async {
    try {
      final service = await _service;
      final file = await service.export(appVersion: await _appVersion);
      final saved = await FilePicker.saveFile(
        fileName: file.name,
        bytes: file.bytes,
        mimeType: 'application/json',
      );
      if (saved == null) return const Ok(null);
      await service.record(file, BackupDestination.saved);
      return Ok(file.name);
    } catch (error, stackTrace) {
      Log.error(error, stackTrace);
      return const Err(AppError.saveFailed);
    }
  }

  /// Share…: the system share sheet, anchored at [origin] on tablets. The
  /// file name once shared, `null` when dismissed.
  Future<Result<String?, AppError>> share({Rect? origin}) async {
    try {
      final service = await _service;
      final file = await service.export(appVersion: await _appVersion);
      try {
        final copy = await service.writeShareCopy(file);
        final result = await SharePlus.instance.share(
          ShareParams(
            files: [XFile(copy.path, mimeType: 'application/json')],
            sharePositionOrigin: origin,
          ),
        );
        if (result.status == ShareResultStatus.dismissed) return const Ok(null);
        await service.record(file, BackupDestination.shared);
        return Ok(file.name);
      } finally {
        await service.deleteShareCopies();
      }
    } catch (error, stackTrace) {
      Log.error(error, stackTrace);
      return const Err(AppError.saveFailed);
    }
  }

  /// Encrypts the next backups with [password]; `null` stops encrypting
  /// them.
  Future<Result<void, AppError>> setPassword(String? password) async {
    try {
      await (await _service).setPassword(password);
      return const Ok(null);
    } catch (error, stackTrace) {
      Log.error(error, stackTrace);
      return const Err(AppError.saveFailed);
    }
  }

  /// Reads and checks [file], then compares it with the current data. An
  /// encrypted file ends in [RestoreNeedsPassword]: [unlock] it.
  Future<Result<RestorePreview, RestoreError>> load(PlatformFile file) async {
    try {
      return await _preview(
        await (await _service).load(
          fileName: file.name,
          size: file.lengthSync() ?? await file.length(),
          read: file.readAsBytes,
        ),
      );
    } catch (error, stackTrace) {
      Log.error(error, stackTrace);
      return const Err(RestoreFailed());
    } finally {
      // The copy some platforms make of a picked file.
      try {
        await FilePicker.clearTemporaryFiles();
      } catch (_) {
        // Not every platform makes one.
      }
    }
  }

  /// Opens an encrypted file with [password], like [load] does a plain one.
  Future<Result<RestorePreview, RestoreError>> unlock(
    PlatformFile file,
    EncryptedBackup encrypted,
    String password,
  ) async {
    try {
      return await _preview(
        await (await _service).unlock(
          fileName: file.name,
          size: file.lengthSync() ?? await file.length() ?? 0,
          file: encrypted,
          password: password,
        ),
      );
    } catch (error, stackTrace) {
      Log.error(error, stackTrace);
      return const Err(RestoreFailed());
    }
  }

  Future<Result<RestorePreview, RestoreError>> _preview(
    Result<LoadedBackup, RestoreError> loaded,
  ) async => switch (loaded) {
    Err(:final error) => Err(error),
    Ok(value: final backup) => Ok(
      RestorePreview(
        backup: backup,
        current: await ref
            .read(backupRepositoryProvider)
            .currentData(
              backup.snapshot.exportedAt,
              before: ref.read(tomorrowProvider),
            ),
      ),
    ),
  };

  /// Replaces every row with [snapshot] after a safety backup. A restore
  /// started from the onboarding ends it.
  Future<Result<void, RestoreError>> restore(AppSnapshot snapshot) async {
    final result = await (await _service).restore(
      snapshot,
      appVersion: await _appVersion,
    );
    if (result is Ok &&
        (ref.read(onboardingProvider).value?.steps.isNotEmpty ?? false)) {
      await ref.read(onboardingProvider.notifier).finish();
    }
    return result;
  }
}
