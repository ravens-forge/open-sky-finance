import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/logging.dart';
import '../../core/result.dart';
import '../../data/models/import_names.dart';
import '../../data/models/import_summary.dart';
import '../../data/providers.dart';
import '../../data/repositories/backup_repository.dart';
import '../../data/repositories/transactions_import_repository.dart';
import '../backup/backup_service.dart';
import '../backup/models/backup_file.dart';
import 'models/import_file_error.dart';
import 'models/parsed_import.dart';
import 'qif_reader.dart';
import 'transactions_csv.dart';

part 'transactions_import_service.g.dart';

/// CSV export of the transactions, and CSV or QIF files added to the
/// current data. The save dialog, share sheet and file picker stay with the
/// caller.
class TransactionsImportService {
  TransactionsImportService({
    required this.backups,
    required this.snapshots,
    required this.repository,
  });

  final BackupService backups;
  final BackupRepository snapshots;
  final TransactionsImportRepository repository;

  /// Larger files are rejected before they are read.
  static const maxSize = 50 * 1024 * 1024;

  /// `open-sky-finance-transactions-YYYYMMDD-HHmmss.csv`, in local time.
  static String fileName(DateTime at) =>
      BackupService.fileName(at)
          .replaceFirst('backup', 'transactions')
          .replaceFirst('.json', '.csv');

  /// Every transaction not in the Trash, read in one transaction and
  /// written in the background.
  Future<BackupFile> exportCsv({
    required String appVersion,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    final snapshot = await snapshots.snapshot(
      appVersion: appVersion,
      exportedAt: at,
    );
    final bytes = await Isolate.run(
      () => utf8.encode(TransactionsCsv.export(snapshot)),
    );
    return BackupFile(name: fileName(at), bytes: bytes);
  }

  /// Reads a picked file of [size] bytes (`null` when unknown) in the
  /// background: QIF when it starts with a `!` header, CSV otherwise.
  /// Ambiguous dates (03/04) read day first when [dayFirst].
  Future<Result<ParsedImport, ImportFileError>> load({
    required int? size,
    required Future<Uint8List> Function() read,
    required bool dayFirst,
  }) async {
    if (size != null && size > maxSize) {
      return const Err(ImportFileError.tooLarge);
    }
    final Uint8List bytes;
    try {
      bytes = await read();
    } on IOException catch (error, stackTrace) {
      Log.error(error, stackTrace);
      return const Err(ImportFileError.failed);
    }
    if (bytes.length > maxSize) return const Err(ImportFileError.tooLarge);
    return Isolate.run(() {
      final String text;
      try {
        text = utf8.decode(bytes);
      } on FormatException {
        // Older apps write Windows-1252 / Latin-1.
        return _parse(latin1.decode(bytes), dayFirst);
      }
      return _parse(text, dayFirst);
    });
  }

  static Result<ParsedImport, ImportFileError> _parse(
    String text,
    bool dayFirst,
  ) {
    if (text.contains('\u0000')) return const Err(ImportFileError.notReadable);
    return QifReader.detect(text)
        ? QifReader.read(text, dayFirst: dayFirst)
        : TransactionsCsv.read(text, dayFirst: dayFirst);
  }

  /// Saves a safety backup, then adds [parsed] in one transaction. On any
  /// failure the data is untouched.
  Future<Result<ImportSummary, ImportFileError>> import(
    ParsedImport parsed, {
    required String appVersion,
    required String mainCurrency,
    required ImportNames names,
    String? assetsAccountId,
  }) async {
    try {
      await backups.saveSafetyCopy(appVersion: appVersion);
      final summary = await repository.importAll(
        parsed.transactions,
        mainCurrency: mainCurrency,
        names: names,
        assetsAccountId: assetsAccountId,
      );
      Log.count('import.transactions', summary.transactions);
      Log.count('import.duplicates', summary.duplicates);
      Log.count('import.invalid', summary.invalid);
      return Ok(summary);
    } catch (error, stackTrace) {
      Log.error(error, stackTrace);
      return const Err(ImportFileError.failed);
    }
  }
}

@Riverpod(keepAlive: true)
Future<TransactionsImportService> transactionsImportService(Ref ref) async =>
    TransactionsImportService(
      backups: await ref.watch(backupServiceProvider.future),
      snapshots: ref.watch(backupRepositoryProvider),
      repository: ref.watch(transactionsImportRepositoryProvider),
    );
