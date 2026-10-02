import '../../core/result.dart';
import '../../data/enums/transaction_type.dart';
import '../../data/models/imported_transaction.dart';
import 'csv_table.dart';
import 'import_values.dart';
import 'models/import_file_error.dart';
import 'models/import_format.dart';
import 'models/parsed_import.dart';

/// Quicken Interchange Format: `!Type:Bank`, `Cash`, `CCard`, `Oth A` and
/// `Oth L` entries, with `!Account` blocks naming the assets account of the
/// entries after them. Investment, category, class and memorized lists are
/// skipped. Pure Dart: runs in an isolate.
abstract final class QifReader {
  static const _transactionTypes = {'bank', 'cash', 'ccard', 'oth a', 'oth l'};

  /// Whether [text] looks like QIF: its first header line.
  static bool detect(String text) =>
      text.trimLeft().replaceFirst(CsvTable.bom, '').startsWith('!');

  static Result<ParsedImport, ImportFileError> read(
    String text, {
    required bool dayFirst,
  }) {
    final lines = text
        .replaceFirst(CsvTable.bom, '')
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trimRight())
        .where((l) => l.isNotEmpty)
        .toList();

    // First pass: the assets accounts the file has entries of, so a
    // transfer between two of them is read once, from the side it leaves.
    final accountsInFile = <String>{};
    String? section;
    for (final (i, line) in lines.indexed) {
      if (line.startsWith('!')) section = line.toLowerCase();
      if (section == '!account' &&
          line.startsWith('N') &&
          (i == 0 || lines[i - 1] == '^' || lines[i - 1].startsWith('!'))) {
        accountsInFile.add(line.substring(1).trim().toLowerCase());
      }
    }

    final entries = <Map<String, String>>[];
    final entryAccounts = <String?>[];
    var inAccount = false;
    var inTransactions = false;
    String? account;
    var entry = <String, String>{};
    for (final line in lines) {
      if (line.startsWith('!')) {
        final header = line.toLowerCase();
        if (header == '!account') {
          inAccount = true;
          inTransactions = false;
        } else if (header.startsWith('!type:')) {
          inAccount = false;
          inTransactions = _transactionTypes.contains(
            header.substring(6).trim(),
          );
        } else if (!header.startsWith('!option') &&
            !header.startsWith('!clear')) {
          inAccount = false;
          inTransactions = false;
        }
        entry = {};
        continue;
      }
      if (line == '^') {
        if (inAccount) {
          account = entry['N'];
          inAccount = false;
        } else if (inTransactions && entry.isNotEmpty) {
          entries.add(entry);
          entryAccounts.add(account);
        }
        entry = {};
        continue;
      }
      final code = line[0];
      final value = line.substring(1).trim();
      // Splits: the first category stands for the whole entry.
      if (code == 'S') {
        entry.putIfAbsent('S', () => value);
      } else {
        entry.putIfAbsent(code, () => value);
      }
    }

    final firstDay = ImportValues.dayFirst(
      entries.map((e) => e['D'] ?? ''),
      fallback: dayFirst,
    );
    final transactions = <ImportedTransaction>[];
    var unreadable = 0;
    for (final (i, e) in entries.indexed) {
      final date = ImportValues.date(e['D'] ?? '', dayFirst: firstDay);
      final amount = ImportValues.amount(e['T'] ?? e['U'] ?? '');
      if (date == null || amount == null || amount == 0) {
        unreadable++;
        continue;
      }
      final from = entryAccounts[i];
      final category = (e['L'] ?? '').isNotEmpty ? e['L']! : (e['S'] ?? '');
      final transfer = RegExp(r'^\[(.+)\]').firstMatch(category)?[1]?.trim();
      final title = e['P'] ?? '';
      final notes = e['M'] ?? '';
      if (transfer != null) {
        // The entering side of a transfer between two assets accounts of
        // the file is the other side's entry.
        if (amount > 0 && accountsInFile.contains(transfer.toLowerCase())) {
          continue;
        }
        transactions.add(
          ImportedTransaction(
            occurredAt: date,
            amount: amount.abs(),
            type: TransactionType.transfer,
            title: title,
            notes: notes,
            assetsAccount: amount < 0 ? from : transfer,
            toAssetsAccount: amount < 0 ? transfer : from,
          ),
        );
        continue;
      }
      // "Food:Groceries/Class": the class is not kept.
      final parts = category.split('/').first.split(':');
      transactions.add(
        ImportedTransaction(
          occurredAt: date,
          amount: amount,
          title: title,
          notes: notes,
          assetsAccount: from,
          categoryGroup: parts.length > 1 ? parts.first.trim() : null,
          category: parts.last.trim().isEmpty ? null : parts.last.trim(),
        ),
      );
    }
    return transactions.isEmpty
        ? Err(
            entries.isEmpty && !lines.any((l) => l.startsWith('!'))
                ? ImportFileError.notReadable
                : ImportFileError.empty,
          )
        : Ok(
            ParsedImport(
              format: ImportFormat.qif,
              transactions: transactions,
              unreadable: unreadable,
            ),
          );
  }
}
