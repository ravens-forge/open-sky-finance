import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/main_currency.dart';
import '../../../core/logging.dart';
import '../../../core/result.dart';
import '../../../data/models/import_names.dart';
import '../../../data/models/import_summary.dart';
import '../../../services/backup/backup_service.dart';
import '../../../services/transactions_import/models/import_file_error.dart';
import '../../../services/transactions_import/transactions_import_service.dart';
import '../../assets_accounts/providers/assets_accounts_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../models/transactions_import_preview.dart';

part 'transactions_import_controller.g.dart';

/// CSV export (Save to… or Share…) and CSV or QIF import.
@Riverpod(keepAlive: true)
class TransactionsImportController extends _$TransactionsImportController {
  @override
  void build() {}

  Future<TransactionsImportService> get _service =>
      ref.read(transactionsImportServiceProvider.future);

  Future<String> get _appVersion => ref.read(appVersionProvider.future);

  /// Save to…: the file name once saved, `null` when cancelled.
  Future<Result<String?, AppError>> saveCsv() async {
    try {
      final file = await (await _service).exportCsv(
        appVersion: await _appVersion,
      );
      final saved = await FilePicker.saveFile(
        fileName: file.name,
        bytes: file.bytes,
        mimeType: 'text/csv',
      );
      return Ok(saved == null ? null : file.name);
    } catch (error, stackTrace) {
      Log.error(error, stackTrace);
      return const Err(AppError.saveFailed);
    }
  }

  /// Share…, anchored at [origin] on tablets: the file name once shared,
  /// `null` when dismissed.
  Future<Result<String?, AppError>> shareCsv({Rect? origin}) async {
    final backups = await ref.read(backupServiceProvider.future);
    try {
      final file = await (await _service).exportCsv(
        appVersion: await _appVersion,
      );
      final copy = await backups.writeShareCopy(file);
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(copy.path, mimeType: 'text/csv')],
          sharePositionOrigin: origin,
        ),
      );
      return Ok(
        result.status == ShareResultStatus.dismissed ? null : file.name,
      );
    } catch (error, stackTrace) {
      Log.error(error, stackTrace);
      return const Err(AppError.saveFailed);
    } finally {
      await backups.deleteShareCopies();
    }
  }

  /// Reads [file] in the background and compares it with the current data.
  /// Ambiguous dates read the way [locale] writes them.
  Future<Result<TransactionsImportPreview, ImportFileError>> load(
    PlatformFile file,
    String locale,
  ) async {
    try {
      final parsed = await (await _service).load(
        size: file.lengthSync() ?? await file.length(),
        read: file.readAsBytes,
        dayFirst: DateFormat.yMd(locale).pattern!.startsWith('d'),
      );
      switch (parsed) {
        case Err(:final error):
          return Err(error);
        case Ok(value: final parsed):
          final accounts = await ref.read(assetsAccountsProvider.future);
          final known = {for (final a in accounts) a.name.toLowerCase()};
          final named = {
            for (final t in parsed.transactions) ...[
              ?t.assetsAccount?.toLowerCase(),
              ?t.toAssetsAccount?.toLowerCase(),
            ],
          };
          final favorite = accounts.where((a) => a.isFavorite).firstOrNull;
          return Ok(
            TransactionsImportPreview(
              fileName: file.name,
              size: file.lengthSync() ?? await file.length() ?? 0,
              parsed: parsed,
              newAssetsAccounts: named.difference(known).length,
              defaultAssetsAccountId: (favorite ?? accounts.firstOrNull)?.id,
            ),
          );
      }
    } catch (error, stackTrace) {
      Log.error(error, stackTrace);
      return const Err(ImportFileError.failed);
    } finally {
      try {
        await FilePicker.clearTemporaryFiles();
      } catch (_) {
        // Not every platform makes a copy.
      }
    }
  }

  /// Adds the previewed transactions after a safety backup, in one
  /// transaction; [names] are what it creates without a name of its own.
  Future<Result<ImportSummary, ImportFileError>> import(
    TransactionsImportPreview preview, {
    required ImportNames names,
    String? assetsAccountId,
  }) async => (await _service).import(
    preview.parsed,
    appVersion: await _appVersion,
    mainCurrency: await ref.read(mainCurrencyProvider.future) ?? 'USD',
    names: names,
    assetsAccountId: assetsAccountId,
  );
}
