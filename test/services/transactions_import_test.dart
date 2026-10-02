import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/core/result.dart';
import 'package:open_sky_finance/data/enums/transaction_type.dart';
import 'package:open_sky_finance/data/models/import_names.dart';
import 'package:open_sky_finance/data/models/imported_transaction.dart';
import 'package:open_sky_finance/data/models/transaction_draft.dart';
import 'package:open_sky_finance/services/transactions_import/csv_table.dart';
import 'package:open_sky_finance/services/transactions_import/import_values.dart';
import 'package:open_sky_finance/services/transactions_import/models/import_file_error.dart';
import 'package:open_sky_finance/services/transactions_import/models/parsed_import.dart';
import 'package:open_sky_finance/services/transactions_import/qif_reader.dart';
import 'package:open_sky_finance/services/transactions_import/transactions_csv.dart';

import '../data/test_db.dart';

const _names = ImportNames(categoryGroup: 'Imported');

ParsedImport _ok(Result<ParsedImport, ImportFileError> r) =>
    (r as Ok<ParsedImport, ImportFileError>).value;

void main() {
  group('values', () {
    test('amounts in every usual notation', () {
      expect(ImportValues.amount('1,234.56'), m(1234.56));
      expect(ImportValues.amount('-1.234,56'), -m(1234.56));
      expect(ImportValues.amount('1 234,5'), m(1234.5));
      expect(ImportValues.amount('(12.00)'), -m(12));
      expect(ImportValues.amount('€ 3,20'), m(3.2));
      expect(ImportValues.amount('1,234'), m(1234));
      expect(ImportValues.amount('0.000001'), 1);
      expect(ImportValues.amount('abc'), isNull);
      expect(ImportValues.formatAmount(-m(54.3)), '-54.30');
      expect(ImportValues.formatAmount(1), '0.000001');
    });

    test('dates: ISO, either order, QIF years', () {
      expect(
        ImportValues.date('2026-09-17', dayFirst: true),
        DateTime(2026, 9, 17),
      );
      expect(
        ImportValues.date('2026-09-17T10:30:00', dayFirst: true),
        DateTime(2026, 9, 17, 10, 30),
      );
      expect(
        ImportValues.date('03/04/2026', dayFirst: true),
        DateTime(2026, 4, 3),
      );
      expect(
        ImportValues.date('03/04/2026 08:15', dayFirst: false),
        DateTime(2026, 3, 4, 8, 15),
      );
      expect(
        ImportValues.date("9/ 5'26", dayFirst: false),
        DateTime(2026, 9, 5),
      );
      expect(ImportValues.date('31/02/2026', dayFirst: true), isNull);
      expect(
        ImportValues.dayFirst(['01/02/2026', '13/02/2026'], fallback: false),
        isTrue,
      );
      expect(
        ImportValues.dayFirst(['01/02/2026', '02/13/2026'], fallback: true),
        isFalse,
      );
      expect(ImportValues.dayFirst(['01/02/2026'], fallback: true), isTrue);
    });

    test('CSV quoting both ways', () {
      final text = CsvTable.encode([
        ['a', 'b,c', 'say "hi"', 'two\nlines', ' pad'],
      ]);
      expect(CsvTable.parse(text), [
        ['a', 'b,c', 'say "hi"', 'two\nlines', ' pad'],
      ]);
    });
  });

  test('QIF: accounts, categories, one side of transfers', () {
    final parsed = _ok(
      QifReader.read(
        File('test/fixtures/import/sample.qif').readAsStringSync(),
        dayFirst: true,
      ),
    );
    final t = parsed.transactions;
    expect(t, hasLength(3));
    expect(parsed.unreadable, 1);
    // 09/20 only reads month first, so the whole file does.
    expect(t[0].occurredAt, DateTime(2026, 9, 3));
    expect(t[0].amount, -m(1234.5));
    expect(t[0].categoryGroup, 'Housing');
    expect(t[0].category, 'Rent');
    expect(t[0].assetsAccount, 'Checking');
    expect(t[1].category, 'Salary');
    expect(t[1].resolvedType, TransactionType.income);
    expect(t[2].type, TransactionType.transfer);
    expect(t[2].amount, m(200));
    expect(t[2].assetsAccount, 'Checking');
    expect(t[2].toAssetsAccount, 'Savings');
    expect(parsed.needsAssetsAccount, isFalse);
  });

  test('CSV of another app: semicolons, aliases, day first', () {
    final parsed = _ok(
      TransactionsCsv.read(
        File('test/fixtures/import/sample.csv').readAsStringSync(),
        dayFirst: false,
      ),
    );
    final t = parsed.transactions;
    expect(t, hasLength(2));
    expect(t[1].occurredAt, DateTime(2026, 9, 18));
    expect(t[1].title, 'Market; stall');
    expect(t[1].notes, 'two\nlines');
    expect(t[1].amount, -m(12));
    expect(t[1].assetsAccount, 'Wallet');
    expect(
      TransactionsCsv.read('Payee,Memo\nx,y', dayFirst: true),
      isA<Err<ParsedImport, ImportFileError>>(),
    );
  });

  test('import: creates what is missing, skips duplicates', () async {
    final db = testDb();
    final checking = await addAssetsAccount(db, 'Checking', currency: 'USD');
    final rows = [
      ImportedTransaction(
        occurredAt: DateTime(2026, 9, 3),
        amount: -m(50),
        title: 'Shop',
        assetsAccount: 'checking',
        categoryGroup: 'Food',
        category: 'Groceries',
        labels: const ['Trip'],
      ),
      ImportedTransaction(
        occurredAt: DateTime(2026, 9, 4),
        amount: m(20),
        type: TransactionType.transfer,
        assetsAccount: 'Checking',
        toAssetsAccount: 'Savings',
      ),
      // Same as the first: a second purchase, both added.
      ImportedTransaction(
        occurredAt: DateTime(2026, 9, 3),
        amount: -m(50),
        title: 'Shop',
        assetsAccount: 'Checking',
        category: 'Groceries',
      ),
      ImportedTransaction(
        occurredAt: DateTime(2026, 9, 5),
        amount: m(10),
        type: TransactionType.transfer,
        assetsAccount: 'Checking',
        toAssetsAccount: 'Checking',
      ),
    ];
    final first = await db.transactionsImportRepository.importAll(
      rows,
      mainCurrency: 'USD',
      names: _names,
    );
    expect(first.transactions, 3);
    expect(first.invalid, 1);
    expect(first.assetsAccounts, 1);
    expect(first.categories, 1);
    expect(first.labels, 1);
    // Groceries without a group found the one just created.
    final categories = await db.customSelect('SELECT id FROM categories').get();
    expect(
      (await db
              .customSelect(
                'SELECT COUNT(*) AS n FROM transactions '
                'WHERE assets_account_id = ? AND category_id IS NOT NULL',
                variables: [Variable.withString(checking)],
              )
              .getSingle())
          .read<int>('n'),
      2,
    );
    expect(categories, isNotEmpty);

    final again = await db.transactionsImportRepository.importAll(
      rows,
      mainCurrency: 'USD',
      names: _names,
    );
    expect(again.transactions, 0);
    expect(again.duplicates, 3);
  });

  test('the CSV export imports back into an empty app', () async {
    final source = testDb();
    final bank = await addAssetsAccount(
      source,
      'Bank',
      currency: 'EUR',
      openingBalance: m(100),
    );
    final group = await addCategoryGroup(source, 'Food');
    final category = await addCategory(source, 'Groceries', groupId: group);
    ok(
      await source.transactionsRepository.save(
        TransactionDraft(
          type: TransactionType.expense,
          occurredAt: DateTime(2026, 9, 10, 18, 30),
          amount: -m(12.34),
          assetsAccountId: bank,
          categoryId: category,
          title: 'Market, "fresh"',
        ),
      ),
    );
    final csv = TransactionsCsv.export(
      await source.backupRepository.snapshot(
        appVersion: '1',
        exportedAt: DateTime(2026, 9, 17),
      ),
    );
    expect(
      csv.split('\r\n').first,
      '${CsvTable.bom}${TransactionsCsv.columns.join(',')}',
    );

    final target = testDb();
    final parsed = _ok(TransactionsCsv.read(csv, dayFirst: true));
    final summary = await target.transactionsImportRepository.importAll(
      parsed.transactions,
      mainCurrency: 'USD',
      names: _names,
    );
    expect(summary.transactions, 1);
    expect(summary.invalid, 0);
    final balance = await target
        .customSelect(
          "SELECT SUM(t.amount) AS s FROM transactions t JOIN assets_accounts a ON a.id = t.assets_account_id WHERE a.name = 'Bank' AND a.currency = 'EUR'",
        )
        .getSingle();
    expect(balance.read<int>('s'), m(100) - m(12.34));
  });
}
