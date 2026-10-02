import 'package:drift/drift.dart';

import '../../core/dates/wall_clock.dart';
import '../../core/finance_colors.dart';
import '../../core/result.dart';
import '../database/app_database.dart';
import '../enums/assets_account_type.dart';
import '../enums/category_kind.dart';
import '../enums/transaction_type.dart';
import '../models/assets_account_draft.dart';
import '../models/category_draft.dart';
import '../models/category_group_draft.dart';
import '../models/import_names.dart';
import '../models/import_summary.dart';
import '../models/imported_transaction.dart';
import '../models/transaction_draft.dart';

part 'transactions_import_repository.g.dart';

/// Adds the transactions of a CSV or QIF file to the current data, in one
/// transaction: assets accounts, categories and labels are found by name
/// (ignoring case) or created, transactions already in the app are left
/// out, and every write goes through the other repositories' rules.
@DriftAccessor()
class TransactionsImportRepository extends DatabaseAccessor<AppDatabase>
    with _$TransactionsImportRepositoryMixin {
  TransactionsImportRepository(super.attachedDatabase);

  /// [assetsAccountId] takes the rows that name no assets account; without
  /// it they are invalid.
  Future<ImportSummary> importAll(
    List<ImportedTransaction> rows, {
    required String mainCurrency,
    required ImportNames names,
    String? assetsAccountId,
  }) => transaction(() async {
    final db = attachedDatabase;
    final accounts = await _byName('SELECT id, name FROM assets_accounts');
    final existingAccounts = accounts.values.toSet();
    final labels = await _byName('SELECT id, name FROM labels');
    var createdAccounts = 0;
    var createdCategories = 0;
    var createdLabels = 0;
    var invalid = 0;

    // Opening balances go into the assets accounts the import creates.
    final openings = <String, ImportedTransaction>{
      for (final r in rows)
        if (r.type == TransactionType.openingBalance && r.assetsAccount != null)
          r.assetsAccount!.toLowerCase(): r,
    };
    final earliest = rows.isEmpty
        ? DateTime.now()
        : rows.map((r) => r.occurredAt).reduce((a, b) => a.isBefore(b) ? a : b);

    Future<String?> account(String? name, String? currency) async {
      if (name == null) return assetsAccountId;
      final key = name.trim().toLowerCase();
      if (accounts[key] case final id?) return id;
      final opening = openings[key];
      final saved = await db.assetsAccountsRepository.save(
        AssetsAccountDraft(
          name: name,
          type: AssetsAccountType.bank,
          currency: currency ?? mainCurrency,
          openingBalance: opening?.amount ?? 0,
          openingBalanceDate: opening?.occurredAt ?? earliest,
        ),
      );
      if (saved case Ok(value: final id)) {
        createdAccounts++;
        return accounts[key] = id;
      }
      return null;
    }

    // Categories by kind, group and name; groups by kind and name.
    final categories = <String, String>{};
    final categoriesAnyGroup = <String, String>{};
    for (final c in await customSelect(
      'SELECT c.id, c.name, g.name AS g, g.kind FROM categories c '
      'JOIN category_groups g ON g.id = c.group_id',
    ).get()) {
      final kind = c.read<String>('kind');
      final name = c.read<String>('name').toLowerCase();
      final id = c.read<String>('id');
      categories['$kind/${c.read<String>('g').toLowerCase()}/$name'] = id;
      categoriesAnyGroup.putIfAbsent('$kind/$name', () => id);
    }
    final groups = <String, String>{
      for (final g in await customSelect(
        'SELECT id, name, kind FROM category_groups',
      ).get())
        '${g.read<String>('kind')}/${g.read<String>('name').toLowerCase()}': g
            .read<String>('id'),
    };

    Future<String?> category(ImportedTransaction r) async {
      final name = r.category?.trim();
      if (name == null || name.isEmpty) return null;
      final kind = r.resolvedType == TransactionType.income
          ? CategoryKind.income
          : CategoryKind.expense;
      final groupName = r.categoryGroup?.trim();
      if (groupName == null || groupName.isEmpty) {
        if (categoriesAnyGroup['${kind.name}/${name.toLowerCase()}']
            case final id?) {
          return id;
        }
      }
      final group = groupName == null || groupName.isEmpty
          ? names.categoryGroup
          : groupName;
      final key = '${kind.name}/${group.toLowerCase()}/${name.toLowerCase()}';
      if (categories[key] case final id?) return id;
      final groupKey = '${kind.name}/${group.toLowerCase()}';
      var groupId = groups[groupKey];
      if (groupId == null) {
        final saved = await db.categoriesRepository.saveGroup(
          CategoryGroupDraft(name: group, kind: kind),
        );
        if (saved case Ok(:final value)) groupId = groups[groupKey] = value;
      }
      if (groupId == null) return null;
      final saved = await db.categoriesRepository.saveCategory(
        CategoryDraft(
          name: name,
          groupId: groupId,
          icon: 'category',
          color: categoryColors[createdCategories % categoryColors.length],
        ),
      );
      if (saved case Ok(value: final id)) {
        createdCategories++;
        categoriesAnyGroup.putIfAbsent(
          '${kind.name}/${name.toLowerCase()}',
          () => id,
        );
        return categories[key] = id;
      }
      return null;
    }

    Future<List<String>> labelIds(List<String> names) async {
      final ids = <String>[];
      for (final name in names.map((n) => n.trim())) {
        if (name.isEmpty) continue;
        var id = labels[name.toLowerCase()];
        if (id == null) {
          final saved = await db.labelsRepository.save(name: name);
          if (saved case Ok(:final value)) {
            id = labels[name.toLowerCase()] = value;
            createdLabels++;
          }
        }
        if (id != null) ids.add(id);
      }
      return ids;
    }

    // Duplicates are checked against the data before the import only: two
    // equal rows in one file are two transactions.
    final drafts = <TransactionDraft>[];
    var duplicates = 0;
    for (final r in rows) {
      final type = r.resolvedType;
      final from = await account(r.assetsAccount, r.currency);
      if (type == TransactionType.openingBalance) {
        // Taken by the assets account it created; one that existed keeps
        // its own.
        if (from == null || existingAccounts.contains(from)) invalid++;
        continue;
      }
      if (from == null) {
        invalid++;
        continue;
      }
      final draft = TransactionDraft(
        type: type,
        occurredAt: r.occurredAt,
        amount: r.amount,
        assetsAccountId: from,
        toAssetsAccountId: type == TransactionType.transfer
            ? await account(r.toAssetsAccount, r.currency)
            : null,
        toAmount: type == TransactionType.transfer ? r.toAmount : null,
        categoryId: type == TransactionType.transfer ? null : await category(r),
        title: r.title.trim(),
        notes: r.notes.trim(),
        labelIds: await labelIds(r.labels),
      );
      if (existingAccounts.contains(from) && await _exists(draft)) {
        duplicates++;
      } else {
        drafts.add(draft);
      }
    }

    var added = 0;
    for (final draft in drafts) {
      final saved = await db.transactionsRepository.save(draft);
      saved is Ok ? added++ : invalid++;
    }
    return ImportSummary(
      transactions: added,
      duplicates: duplicates,
      invalid: invalid,
      assetsAccounts: createdAccounts,
      categories: createdCategories,
      labels: createdLabels,
    );
  });

  Future<Map<String, String>> _byName(String sql) async => {
    for (final row in await customSelect(sql).get())
      row.read<String>('name').toLowerCase(): row.read<String>('id'),
  };

  Future<bool> _exists(TransactionDraft d) async =>
      await customSelect(
        'SELECT 1 FROM transactions WHERE assets_account_id = ? '
        'AND occurred_at = ? AND amount = ? AND title = ? AND type = ? '
        'AND deleted_at IS NULL LIMIT 1',
        variables: [
          Variable.withString(d.assetsAccountId),
          Variable.withString(formatWallClock(d.occurredAt)),
          Variable.withInt(d.amount),
          Variable.withString(d.title),
          Variable.withString(d.type.name),
        ],
      ).getSingleOrNull() !=
      null;
}
