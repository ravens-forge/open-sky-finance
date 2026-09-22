import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/l10n.dart';
import '../../../core/logging.dart';
import '../../../data/models/data_counts.dart';
import '../../../data/providers.dart';
import '../../../services/backup/backup_folders.dart';

part 'erase_controller.g.dart';

@Riverpod(keepAlive: true)
class EraseController extends _$EraseController {
  @override
  DataCounts? build() => null;

  Future<DataCounts> counts() => ref.read(eraseRepositoryProvider).counts();

  /// Erases everything and seeds the defaults again in [l10n]'s language.
  /// `false` when it failed and nothing was deleted.
  Future<bool> eraseAll(AppLocalizations l10n) async {
    final repository = ref.read(eraseRepositoryProvider);
    try {
      final counts = await repository.counts();
      await repository.eraseAll(
        l10n,
        currency: deviceCurrency(PlatformDispatcher.instance.locale),
      );
      state = counts;
    } catch (error, stackTrace) {
      Log.error(error, stackTrace);
      return false;
    }
    // The data is gone either way: a failed clean-up is only logged.
    try {
      for (final folder in await ref.read(backupCopyFoldersProvider.future)) {
        if (await folder.exists()) await folder.delete(recursive: true);
      }
      await repository.vacuum();
    } catch (error, stackTrace) {
      Log.error(error, stackTrace);
    }
    return true;
  }
}
