import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/now.dart';
import '../../../core/logging.dart';
import '../../../core/result.dart';
import '../../../data/models/app_snapshot.dart';
import '../../../services/bluecoins/bluecoins_service.dart';
import '../../../services/bluecoins/models/bluecoins_import_error.dart';
import '../../settings/providers/settings_providers.dart';
import '../models/bluecoins_preview.dart';
import 'backup_controller.dart';

part 'bluecoins_import_controller.g.dart';

@Riverpod(keepAlive: true)
class BluecoinsImportController extends _$BluecoinsImportController {
  @override
  void build() {}

  /// Copies, checks and maps [file]; the picked file itself is never changed.
  Future<Result<BluecoinsPreview, BluecoinsImportError>> load(
    PlatformFile file,
  ) async {
    try {
      final loaded = await (await ref.read(bluecoinsServiceProvider.future))
          .load(
            fileName: file.name,
            size: await file.length(),
            read: file.readAsByteStream,
            appVersion: await ref.read(appVersionProvider.future),
            now: ref.read(nowProvider),
          );
      return switch (loaded) {
        Ok(:final value) => Ok(
          BluecoinsPreview.of(value, before: ref.read(tomorrowProvider)),
        ),
        Err(:final error) => Err(error),
      };
    } catch (error, stackTrace) {
      Log.error(error, stackTrace);
      return const Err(BluecoinsImportFailed());
    } finally {
      // The copy some platforms make of a picked file.
      try {
        await FilePicker.clearTemporaryFiles();
      } catch (_) {
        // Not every platform makes one.
      }
    }
  }

  /// Writes [snapshot] the way a restore does: safety backup first, one
  /// transaction, and the onboarding ends if it was open.
  Future<Result<void, BluecoinsImportError>> import(
    AppSnapshot snapshot,
  ) async => switch (await ref
      .read(backupControllerProvider.notifier)
      .restore(snapshot)) {
    Ok() => const Ok(null),
    Err() => const Err(BluecoinsImportFailed()),
  };
}
