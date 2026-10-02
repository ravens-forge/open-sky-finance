import '../../core/result.dart';
import '../../data/enums/transaction_type.dart';
import '../../data/models/app_snapshot.dart';
import '../../data/models/imported_transaction.dart';
import 'csv_table.dart';
import 'import_values.dart';
import 'models/import_file_error.dart';
import 'models/import_format.dart';
import 'models/parsed_import.dart';

/// Transactions as CSV: the app's export, and the files it imports (its own
/// and other apps' with similar columns). Pure Dart: runs in an isolate.
abstract final class TransactionsCsv {
  /// The export's columns, in order. Locale-independent, like backups.
  static const columns = [
    'date',
    'type',
    'title',
    'amount',
    'currency',
    'assets_account',
    'to_assets_account',
    'to_amount',
    'category_group',
    'category',
    'labels',
    'notes',
  ];

  /// Other names a column goes by in other apps' files.
  static const _aliases = {
    'payee': 'title',
    'description': 'title',
    'memo': 'notes',
    'note': 'notes',
    'account': 'assets_account',
    'from_account': 'assets_account',
    'to_account': 'to_assets_account',
    'amount_received': 'to_amount',
    'group': 'category_group',
    'parent_category': 'category_group',
    'tags': 'labels',
    'label': 'labels',
  };

  /// Labels share a cell, split by this.
  static const _labelSeparator = '; ';

  /// Every transaction not in the Trash, oldest first, opening balances
  /// included, so importing the file into an empty app rebuilds the
  /// balances.
  static String export(AppSnapshot s) {
    final accounts = {for (final a in s.assetsAccounts) a.id: a.name};
    final groups = {for (final g in s.categoryGroups) g.id: g.name};
    final categories = {for (final c in s.categories) c.id: c};
    final labelNames = {for (final l in s.labels) l.id: l.name};
    final labels = <String, List<String>>{};
    for (final tl in s.transactionLabels) {
      (labels[tl.transactionId] ??= []).add(labelNames[tl.labelId] ?? '');
    }
    final rows = [
      for (final t in s.transactions)
        if (t.deletedAt == null) t,
    ]..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return CsvTable.encode([
      columns,
      for (final t in rows)
        [
          t.occurredAt.toIso8601String().substring(0, 19),
          t.type.name,
          t.title,
          ImportValues.formatAmount(t.amount),
          t.currency,
          accounts[t.assetsAccountId] ?? '',
          accounts[t.toAssetsAccountId] ?? '',
          t.toAmount == null ? '' : ImportValues.formatAmount(t.toAmount!),
          groups[categories[t.categoryId]?.groupId] ?? '',
          categories[t.categoryId]?.name ?? '',
          ((labels[t.id] ?? [])..sort()).join(_labelSeparator),
          t.notes,
        ],
    ]);
  }

  /// The transactions of a CSV file with a header row. Columns are found
  /// by name (case, spaces and `_` ignored); `date` and `amount` are
  /// required. Dates read day first when [dayFirst] and nothing in the file
  /// says otherwise.
  static Result<ParsedImport, ImportFileError> read(
    String text, {
    required bool dayFirst,
  }) {
    final table = CsvTable.parse(text);
    if (table.isEmpty) return const Err(ImportFileError.empty);
    String key(String name) {
      final k = name.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '_');
      return _aliases[k] ?? k;
    }

    final header = {for (final (i, name) in table.first.indexed) key(name): i};
    if (!header.containsKey('date') || !header.containsKey('amount')) {
      return const Err(ImportFileError.missingColumns);
    }
    String? cell(List<String> row, String column) {
      final i = header[column];
      final value = i == null || i >= row.length ? '' : row[i].trim();
      return value.isEmpty ? null : value;
    }

    final rows = table.skip(1).toList();
    final firstDay = ImportValues.dayFirst(
      rows.map((r) => cell(r, 'date') ?? ''),
      fallback: dayFirst,
    );
    final transactions = <ImportedTransaction>[];
    var unreadable = 0;
    for (final row in rows) {
      final date = ImportValues.date(
        cell(row, 'date') ?? '',
        dayFirst: firstDay,
      );
      final amount = ImportValues.amount(cell(row, 'amount') ?? '');
      final type = TransactionType.values.asNameMap()[cell(row, 'type')];
      if (date == null || amount == null || amount == 0) {
        unreadable++;
        continue;
      }
      final toAmount = cell(row, 'to_amount');
      final isTransfer = type == TransactionType.transfer;
      transactions.add(
        ImportedTransaction(
          occurredAt: date,
          // A transfer leaves its assets account: written as a positive
          // amount whatever sign the file gives it.
          amount: isTransfer ? amount.abs() : amount,
          type: type,
          title: cell(row, 'title') ?? '',
          notes: cell(row, 'notes') ?? '',
          assetsAccount: cell(row, 'assets_account'),
          toAssetsAccount: isTransfer ? cell(row, 'to_assets_account') : null,
          toAmount: isTransfer && toAmount != null
              ? ImportValues.amount(toAmount)?.abs()
              : null,
          categoryGroup: cell(row, 'category_group'),
          category: cell(row, 'category'),
          labels: (cell(row, 'labels') ?? '')
              .split(';')
              .map((l) => l.trim())
              .where((l) => l.isNotEmpty)
              .toList(),
          currency: cell(row, 'currency')?.toUpperCase(),
        ),
      );
    }
    return transactions.isEmpty
        ? const Err(ImportFileError.empty)
        : Ok(
            ParsedImport(
              format: ImportFormat.csv,
              transactions: transactions,
              unreadable: unreadable,
            ),
          );
  }
}
