import 'dart:convert';

import 'package:decimal/decimal.dart';

import '../../data/database/app_database.dart';
import '../../data/database/tables/assets_accounts_table.dart';
import '../../data/database/tables/categories_table.dart';
import '../../data/database/tables/category_groups_table.dart';
import '../../data/database/tables/labels_table.dart';
import '../../data/database/tables/reminders_table.dart';
import '../../data/database/tables/transactions_table.dart';
import '../../data/enums/assets_account_type.dart';
import '../../data/enums/budget_period.dart';
import '../../data/enums/category_kind.dart';
import '../../data/enums/reminder_frequency.dart';
import '../../data/enums/transaction_type.dart';
import '../../data/models/app_snapshot.dart';
import '../../data/models/home_section.dart';
import '../../data/repositories/setting_keys.dart';
import 'json_fields.dart';
import 'models/backup_problem_code.dart';

const _locales = {'en', 'es', 'fr'};
const _themeModes = {'system', 'light', 'dark'};

/// Reads a backup's top-level object (already upgraded to the current
/// version) into rows, and checks what the tables cannot on their own:
/// unique ids, references inside the file and the transaction rules. Every
/// problem goes to [problems]; the snapshot is only usable when there is
/// none.
AppSnapshot readBackup(JsonFields root, ProblemCollector problems) {
  final data = root.object('data') ?? JsonFields(const {}, 'data', problems);
  final reader = _Reader(problems);
  final snapshot = AppSnapshot(
    appVersion: root.string('appVersion'),
    exportedAt: root.instant('exportedAt'),
    settings: _settings(data.object('settings')),
    assetsAccounts: [
      for (final a in data.objects('assetsAccounts')) reader.assetsAccount(a),
    ],
    categoryGroups: [
      for (final g in data.objects('categoryGroups')) reader.categoryGroup(g),
    ],
    categories: [
      for (final c in data.objects('categories')) reader.category(c),
    ],
    labels: [for (final l in data.objects('labels')) reader.label(l)],
    reminders: [
      for (final r in data.objects('reminders', optional: true))
        reader.reminder(r),
    ],
    reminderLabels: reader.reminderLabels,
    transactions: [
      for (final t in data.objects('transactions')) reader.transaction(t),
    ],
    transactionLabels: reader.transactionLabels,
  );
  reader.check(snapshot);
  return snapshot;
}

/// Stored values of the backed-up settings; unknown keys are ignored.
Map<String, String> _settings(JsonFields? json) {
  if (json == null) return const {};
  final settings = <String, String>{};
  if (json.has('mainCurrency')) {
    settings[SettingKeys.mainCurrency] = json.currency('mainCurrency');
  }
  if (json.nullableString('themeMode') case final mode?) {
    if (!_themeModes.contains(mode)) json.invalid('themeMode');
    settings[SettingKeys.themeMode] = mode;
  }
  // Unknown languages follow the device.
  if (json.nullableString('locale') case final locale?
      when _locales.contains(locale)) {
    settings[SettingKeys.locale] = locale;
  }
  if (json.nullableInteger('firstDayOfWeek') case final day?) {
    if (day < DateTime.monday || day > DateTime.sunday) {
      json.invalid('firstDayOfWeek');
    }
    settings[SettingKeys.firstDayOfWeek] = '$day';
  }
  if (json.has('homeSections')) {
    final sections = json.objects('homeSections');
    // Unknown ids are dropped and missing ones appended, as when the app
    // reads its own setting.
    settings[SettingKeys.homeSections] = HomeSection.listToJson(
      HomeSection.listFromJson(
        jsonEncode([
          for (final s in sections)
            {'id': s.string('id'), 'visible': s.boolean('visible')},
        ]),
      ),
    );
  }
  return settings;
}

class _Reader {
  _Reader(this.problems);

  final ProblemCollector problems;
  final reminderLabels = <ReminderLabelTableRow>[];
  final transactionLabels = <TransactionLabelTableRow>[];

  /// Where each row came from, by its position in its list.
  final _paths = <Object, String>{};

  /// Label ids of each reminder or transaction, by its path.
  final _labelIds = <String, List<String>>{};

  T _at<T extends Object>(T row, JsonFields json) {
    _paths[row] = json.path;
    return row;
  }

  /// A positive amount when a budget is there.
  void _checkBudget(JsonFields json, int? amount) {
    if (amount != null && amount <= 0) {
      json.object('budget')?.invalid('amount');
    }
  }

  AssetsAccountTableRow assetsAccount(JsonFields a) => _at(
    AssetsAccountTableRow(
      id: a.id('id'),
      name: a.name('name'),
      type: a.enumValue('type', AssetsAccountType.values),
      currency: a.currency('currency'),
      isHidden: a.boolean('isHidden'),
      isFavorite: a.boolean('isFavorite', orElse: false),
      excludeFromNetWorth: a.boolean('excludeFromNetWorth'),
      creditLimit: a.nullableMoney('creditLimit'),
      sortOrder: a.integer('sortOrder'),
      notes: a.string('notes'),
      createdAt: a.instant('createdAt'),
      updatedAt: a.instant('updatedAt'),
    ),
    a,
  );

  CategoryGroupTableRow categoryGroup(JsonFields g) {
    final budget = g.object('budget', optional: true);
    final row = CategoryGroupTableRow(
      id: g.id('id'),
      name: g.name('name'),
      kind: g.enumValue('kind', CategoryKind.values),
      isHidden: g.boolean('isHidden'),
      sortOrder: g.integer('sortOrder'),
      budgetAmount: budget?.money('amount'),
      budgetPeriod: budget?.enumValue('period', BudgetPeriod.values),
      budgetRollover: budget?.boolean('rollover', orElse: false) ?? false,
    );
    _checkBudget(g, row.budgetAmount);
    return _at(row, g);
  }

  CategoryTableRow category(JsonFields c) {
    final budget = c.object('budget', optional: true);
    final row = CategoryTableRow(
      id: c.id('id'),
      name: c.name('name'),
      groupId: c.id('groupId'),
      icon: c.string('icon'),
      color: c.integer('color'),
      isHidden: c.boolean('isHidden'),
      sortOrder: c.integer('sortOrder'),
      budgetAmount: budget?.money('amount'),
      budgetPeriod: budget?.enumValue('period', BudgetPeriod.values),
      budgetRollover: budget?.boolean('rollover', orElse: false) ?? false,
    );
    _checkBudget(c, row.budgetAmount);
    return _at(row, c);
  }

  LabelTableRow label(JsonFields l) =>
      _at(LabelTableRow(id: l.id('id'), name: l.name('name')), l);

  ReminderTableRow reminder(JsonFields r) {
    final row = _at(
      ReminderTableRow(
        id: r.id('id'),
        type: r.enumValue('type', TransactionType.values),
        title: r.string('title', orElse: ''),
        amount: r.money('amount'),
        assetsAccountId: r.id('assetsAccountId'),
        toAssetsAccountId: r.nullableId('toAssetsAccountId'),
        toAmount: r.nullableMoney('toAmount'),
        categoryId: r.nullableId('categoryId'),
        currency: r.currency('currency'),
        notes: r.string('notes', orElse: ''),
        frequency: r.enumValue('frequency', ReminderFrequency.values),
        interval: r.has('interval') ? r.integer('interval') : 1,
        startDate: r.wallClock('startDate'),
        nextDueAt: r.nullableWallClock('nextDueAt'),
        endDate: r.nullableWallClock('endDate'),
        remainingOccurrences: r.nullableInteger('remainingOccurrences'),
        autoPost: r.boolean('autoPost', orElse: false),
        notify: r.boolean('notify', orElse: false),
        isPaused: r.boolean('isPaused', orElse: false),
        sortOrder: r.integer('sortOrder'),
        createdAt: r.instant('createdAt'),
        updatedAt: r.instant('updatedAt'),
      ),
      r,
    );
    if (row.interval < 1) r.invalid('interval');
    final labelIds = _labelIds[r.path] = r.ids('labelIds');
    reminderLabels.addAll([
      for (final id in labelIds)
        ReminderLabelTableRow(reminderId: row.id, labelId: id),
    ]);
    return row;
  }

  TransactionTableRow transaction(JsonFields t) {
    final row = _at(
      TransactionTableRow(
        id: t.id('id'),
        type: t.enumValue('type', TransactionType.values),
        occurredAt: t.wallClock('occurredAt'),
        title: t.string('title', orElse: ''),
        amount: t.money('amount'),
        assetsAccountId: t.id('assetsAccountId'),
        toAssetsAccountId: t.nullableId('toAssetsAccountId'),
        toAmount: t.nullableMoney('toAmount'),
        categoryId: t.nullableId('categoryId'),
        currency: t.currency('currency'),
        exchangeRate: t.nullableString('exchangeRate'),
        notes: t.string('notes', orElse: ''),
        reminderId: t.nullableId('reminderId'),
        deletedAt: t.nullableInstant('deletedAt'),
        createdAt: t.instant('createdAt'),
        updatedAt: t.instant('updatedAt'),
      ),
      t,
    );
    if (row.exchangeRate case final rate? when Decimal.tryParse(rate) == null) {
      t.invalid('exchangeRate');
    }
    final labelIds = _labelIds[t.path] = t.ids('labelIds');
    transactionLabels.addAll([
      for (final id in labelIds)
        TransactionLabelTableRow(transactionId: row.id, labelId: id),
    ]);
    return row;
  }

  void _problem(BackupProblemCode code, Object row, String field) =>
      problems.add(code, '${_paths[row]}.$field');

  /// Ids of [rows], each once, recording the duplicates.
  Map<String, T> _unique<T extends Object>(
    List<T> rows,
    String Function(T row) id,
  ) {
    final byId = <String, T>{};
    for (final row in rows) {
      if (byId.containsKey(id(row))) {
        _problem(BackupProblemCode.duplicateId, row, 'id');
      } else {
        byId[id(row)] = row;
      }
    }
    return byId;
  }

  void check(AppSnapshot s) {
    final accounts = _unique(s.assetsAccounts, (a) => a.id);
    final groups = _unique(s.categoryGroups, (g) => g.id);
    final categories = _unique(s.categories, (c) => c.id);
    final labels = _unique(s.labels, (l) => l.id);
    final reminders = _unique(s.reminders, (r) => r.id);
    _unique(s.transactions, (t) => t.id);

    final names = <String>{};
    for (final label in s.labels) {
      if (!names.add(label.name.toLowerCase())) {
        _problem(BackupProblemCode.duplicateName, label, 'name');
      }
    }

    // Only spending is budgeted.
    for (final g in s.categoryGroups) {
      if (g.budgetAmount != null && g.kind != CategoryKind.expense) {
        _problem(BackupProblemCode.brokenRule, g, 'budget');
      }
    }
    for (final c in s.categories) {
      final group = groups[c.groupId];
      if (group == null) {
        _problem(BackupProblemCode.unknownReference, c, 'groupId');
      } else if (c.budgetAmount != null && group.kind != CategoryKind.expense) {
        _problem(BackupProblemCode.brokenRule, c, 'budget');
      }
    }

    CategoryKind? kindOf(String id) => groups[categories[id]?.groupId]?.kind;

    void labelsOf(Object row) {
      final ids = _labelIds[_paths[row]] ?? const [];
      final seen = <String>{};
      for (final (i, id) in ids.indexed) {
        if (id.isEmpty) continue;
        if (!labels.containsKey(id)) {
          _problem(BackupProblemCode.unknownReference, row, 'labelIds[$i]');
        } else if (!seen.add(id)) {
          _problem(BackupProblemCode.duplicateId, row, 'labelIds[$i]');
        }
      }
    }

    for (final r in s.reminders) {
      if (r.type == TransactionType.openingBalance) {
        _problem(BackupProblemCode.brokenRule, r, 'type');
      }
      _movement(
        r,
        accounts,
        kindOf,
        type: r.type,
        amount: r.amount,
        from: r.assetsAccountId,
        to: r.toAssetsAccountId,
        toAmount: r.toAmount,
        categoryId: r.categoryId,
        currency: r.currency,
        exchangeRate: null,
      );
      labelsOf(r);
    }
    for (final t in s.transactions) {
      _movement(
        t,
        accounts,
        kindOf,
        type: t.type,
        amount: t.amount,
        from: t.assetsAccountId,
        to: t.toAssetsAccountId,
        toAmount: t.toAmount,
        categoryId: t.categoryId,
        currency: t.currency,
        exchangeRate: t.exchangeRate,
      );
      if (t.reminderId case final id? when !reminders.containsKey(id)) {
        _problem(BackupProblemCode.unknownReference, t, 'reminderId');
      }
      labelsOf(t);
    }
  }

  /// The rules shared by transactions and reminders.
  void _movement(
    Object row,
    Map<String, AssetsAccountTableRow> accounts,
    CategoryKind? Function(String categoryId) kindOf, {
    required TransactionType type,
    required int amount,
    required String from,
    required String? to,
    required int? toAmount,
    required String? categoryId,
    required String currency,
    required String? exchangeRate,
  }) {
    void broken(String field) =>
        _problem(BackupProblemCode.brokenRule, row, field);
    void unknown(String field) =>
        _problem(BackupProblemCode.unknownReference, row, field);

    final source = accounts[from];
    if (source == null) {
      unknown('assetsAccountId');
    } else if (source.currency != currency) {
      broken('currency');
    }
    if (categoryId != null && kindOf(categoryId) == null) {
      unknown('categoryId');
    }

    if (type != TransactionType.transfer) {
      if (to != null) broken('toAssetsAccountId');
      if (toAmount != null) broken('toAmount');
      if (exchangeRate != null) broken('exchangeRate');
      final kind = categoryId == null ? null : kindOf(categoryId);
      final wanted = switch (type) {
        TransactionType.income => CategoryKind.income,
        TransactionType.expense => CategoryKind.expense,
        _ => null,
      };
      if (kind != null && kind != wanted) broken('categoryId');
      return;
    }

    if (amount <= 0) broken('amount');
    if (categoryId != null) broken('categoryId');
    if (to == null) {
      problems.add(
        BackupProblemCode.missing,
        '${_paths[row]}.toAssetsAccountId',
      );
      return;
    }
    final target = accounts[to];
    if (target == null) {
      unknown('toAssetsAccountId');
    } else if (to == from) {
      broken('toAssetsAccountId');
    }
    if (toAmount != null && toAmount <= 0) broken('toAmount');
    if (source != null && target != null) {
      // Between currencies the amount received is required; otherwise it is
      // the amount sent.
      final between = source.currency != target.currency;
      if (between != (toAmount != null)) broken('toAmount');
      if (!between && exchangeRate != null) broken('exchangeRate');
    }
  }
}
