import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import '../../core/logging.dart';
import '../../core/result.dart';
import 'models/bluecoins_import_error.dart';
import 'models/bluecoins_tables.dart';

/// The columns read from each table. Tables with `required: true` must be in
/// the file; the others are read when present. Only these fixed queries run
/// against the file, never SQL taken from it.
const _tables = [
  _Table('ACCOUNTSTABLE', [
    'accountsTableID',
    'accountName',
    'accountTypeID',
    'accountHidden',
    'accountCurrency',
    'creditLimit',
  ], required: true),
  _Table('ACCOUNTTYPETABLE', ['accountTypeTableID', 'accountingGroupID']),
  _Table('PARENTCATEGORYTABLE', [
    'parentCategoryTableID',
    'parentCategoryName',
    'categoryGroupID',
    'budgetAmountCategoryParent',
    'budgetEnabledCategoryParent',
  ], required: true),
  _Table('CHILDCATEGORYTABLE', [
    'categoryTableID',
    'childCategoryName',
    'parentCategoryID',
    'childCategoryIcon',
    'budgetAmount',
    'budgetEnabledCategoryChild',
  ], required: true),
  _Table('ITEMTABLE', ['itemTableID', 'itemName'], required: true),
  _Table('TRANSACTIONSTABLE', [
    'transactionsTableID',
    'itemID',
    'uidPairID',
    'amount',
    'transactionCurrency',
    'date',
    'transactionTypeID',
    'categoryID',
    'accountID',
    'notes',
    'accountReference',
    'deletedTransaction',
    'newSplitTransactionID',
    'transferGroupID',
    'reminderTransaction',
  ], required: true),
  _Table('LABELSTABLE', ['labelName', 'transactionIDLabels']),
  _Table('SETTINGSTABLE', ['settingsTableID', 'defaultSettings']),
];

/// The first 16 bytes of every SQLite 3 database.
const _sqliteMagic = 'SQLite format 3\x00';

/// Reads a Bluecoins backup (a plain SQLite database) without ever writing
/// to it. Synchronous, for a background isolate.
abstract final class BluecoinsReader {
  /// Checks and reads the database at [path], which must be a private copy.
  static Result<BluecoinsTables, BluecoinsImportError> read(String path) {
    final head = _head(path);
    if (head.startsWith('PK')) return const Err(BluecoinsCompressed());
    if (head != _sqliteMagic) return const Err(BluecoinsNotABackup());

    final Database db;
    try {
      db = sqlite3.open(path, mode: OpenMode.readOnly);
    } on SqliteException catch (error, stackTrace) {
      Log.error(error, stackTrace);
      return const Err(BluecoinsDamaged());
    }
    try {
      final check = db.select('PRAGMA quick_check');
      if (check.length != 1 || check.single.values.first != 'ok') {
        return const Err(BluecoinsDamaged());
      }

      final names = {
        for (final row in db.select(
          "SELECT name FROM sqlite_master WHERE type = 'table'",
        ))
          row['name'] as String,
      };
      if (_tables.any((t) => t.required && !names.contains(t.name))) {
        return const Err(BluecoinsNotABackup());
      }
      final missing = <String>[];
      for (final table in _tables.where((t) => names.contains(t.name))) {
        final columns = {
          for (final row in db.select('PRAGMA table_info("${table.name}")'))
            row['name'] as String,
        };
        missing.addAll([
          for (final c in table.columns)
            if (!columns.contains(c)) '${table.name}.$c',
        ]);
      }
      if (missing.isNotEmpty) return Err(BluecoinsMissingColumns(missing));

      List<Map<String, Object?>> rows(String table) {
        if (!names.contains(table)) return const [];
        final columns = _tables.firstWhere((t) => t.name == table).columns;
        return db
            .select(
              'SELECT ${columns.map((c) => '"$c"').join(', ')} FROM "$table"',
            )
            .toList();
      }

      return Ok(
        BluecoinsTables(
          userVersion: db.userVersion,
          accountTypes: rows('ACCOUNTTYPETABLE'),
          accounts: rows('ACCOUNTSTABLE'),
          parentCategories: rows('PARENTCATEGORYTABLE'),
          childCategories: rows('CHILDCATEGORYTABLE'),
          items: rows('ITEMTABLE'),
          transactions: rows('TRANSACTIONSTABLE'),
          labels: rows('LABELSTABLE'),
          settings: rows('SETTINGSTABLE'),
        ),
      );
    } on SqliteException catch (error, stackTrace) {
      // Encrypted or damaged beyond what quick_check reports.
      Log.error(error, stackTrace);
      return const Err(BluecoinsDamaged());
    } finally {
      db.close();
    }
  }

  /// The first bytes of the file, one character per byte.
  static String _head(String path) {
    final file = File(path).openSync();
    try {
      return latin1.decode(file.readSync(_sqliteMagic.length));
    } finally {
      file.closeSync();
    }
  }
}

class _Table {
  const _Table(this.name, this.columns, {this.required = false});

  final String name;
  final List<String> columns;
  final bool required;
}
