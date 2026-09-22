import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/logging.dart';
import '../../../core/result.dart';
import '../../../data/models/app_snapshot.dart';
import '../../../data/providers.dart';
import '../../../services/backup/backup_service.dart';
import '../../../services/backup/models/backup_destination.dart';
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

  /// Reads and checks [file], then compares it with the current data.
  Future<Result<RestorePreview, RestoreError>> load(PlatformFile file) async {
    try {
      final loaded = await (await _service).load(
        fileName: file.name,
        size: file.lengthSync() ?? await file.length(),
        read: file.readAsBytes,
      );
      switch (loaded) {
        case Err(:final error):
          return Err(error);
        case Ok(value: final backup):
          return Ok(
            RestorePreview(
              backup: backup,
              current: await ref
                  .read(backupRepositoryProvider)
                  .currentData(backup.snapshot.exportedAt),
            ),
          );
      }
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
