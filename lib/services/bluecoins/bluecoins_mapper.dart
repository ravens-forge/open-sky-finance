import '../../core/dates/wall_clock.dart';
import '../../core/finance_colors.dart';
import '../../core/ids.dart';
import '../../core/widgets/category_icons.dart';
import '../../data/database/app_database.dart';
import '../../data/database/tables/assets_accounts_table.dart';
import '../../data/database/tables/categories_table.dart';
import '../../data/database/tables/category_groups_table.dart';
import '../../data/database/tables/labels_table.dart';
import '../../data/database/tables/transactions_table.dart';
import '../../data/enums/assets_account_type.dart';
import '../../data/enums/category_kind.dart';
import '../../data/enums/transaction_type.dart';
import '../../data/models/app_snapshot.dart';
import '../../data/repositories/setting_keys.dart';
import '../backup/json_fields.dart';
import 'models/bluecoins_import.dart';
import 'models/bluecoins_import_report.dart';
import 'models/bluecoins_note.dart';
import 'models/bluecoins_skip_reason.dart';
import 'models/bluecoins_tables.dart';

/// `ACCOUNTSTABLE.accountTypeID` → type. Other ids fall back to their
/// accounting group.
const _assetsAccountTypes = {
  1: AssetsAccountType.otherAsset,
  2: AssetsAccountType.otherLiability,
  3: AssetsAccountType.bank,
  4: AssetsAccountType.cash,
  5: AssetsAccountType.investment,
  6: AssetsAccountType.receivable,
  7: AssetsAccountType.property,
  8: AssetsAccountType.creditCard,
  9: AssetsAccountType.loan,
  10: AssetsAccountType.payable,
  11: AssetsAccountType.mortgage,
  12: AssetsAccountType.externalAsset,
  13: AssetsAccountType.externalLiability,
  15: AssetsAccountType.virtual,
  16: AssetsAccountType.crypto,
};

/// `PARENTCATEGORYTABLE.categoryGroupID` → kind; 0 and 1 are system groups.
const _categoryKinds = {2: CategoryKind.income, 3: CategoryKind.expense};

/// `deletedTransaction` values.
const _active = 6;
const _deleted = 5;

/// `accountReference` values of transfer legs.
const _sourceLeg = 1;
const _destinationLeg = 2;

final _currency = RegExp(r'^[A-Z]{3}$');
final _upperCase = RegExp(r'(?<!^)[A-Z]');

/// A Bluecoins backup → the rows a restore writes, plus what was left out and
/// why. Matches by id only: reference names are in the device's language.
/// Pure Dart, for a background isolate.
abstract final class BluecoinsMapper {
  /// [settings] are the current backed-up settings: the import keeps them
  /// and only sets the main currency. Balances and ids use [now].
  static BluecoinsImport map(
    BluecoinsTables source, {
    required DateTime now,
    required String appVersion,
    Map<String, String> settings = const {},
  }) => _Mapping(source, now.toUtc()).run(appVersion, settings);

  /// `Outlined.LocalGasStation` → `local_gas_station`, when the app has it.
  static String icon(String? value) {
    final name = (value ?? '').split('.').last;
    final key = name
        .replaceAllMapped(_upperCase, (m) => '_${m[0]}')
        .toLowerCase();
    return categoryIcons.containsKey(key) ? key : 'category';
  }
}

class _Mapping {
  _Mapping(this.source, this.now);

  final BluecoinsTables source;

  /// UTC.
  final DateTime now;

  final skipped = <BluecoinsSkipReason, int>{};
  final noted = <BluecoinsNote, int>{};

  final accounts = <int, AssetsAccountTableRow>{};
  final groups = <int, CategoryGroupTableRow>{};
  final categories = <int, CategoryTableRow>{};
  final transactions = <TransactionTableRow>[];
  final labels = <LabelTableRow>[];
  final transactionLabels = <TransactionLabelTableRow>[];

  /// Our transaction id of each imported Bluecoins row, both transfer legs
  /// included.
  final transactionIds = <int, String>{};

  void skip(BluecoinsSkipReason reason) =>
      skipped[reason] = (skipped[reason] ?? 0) + 1;

  void note(BluecoinsNote note) => noted[note] = (noted[note] ?? 0) + 1;

  BluecoinsImport run(String appVersion, Map<String, String> settings) {
    _assetsAccounts();
    _categories();
    _transactions();
    _labels();
    return BluecoinsImport(
      snapshot: AppSnapshot(
        appVersion: appVersion,
        exportedAt: now,
        settings: {...settings, ..._mainCurrency()},
        assetsAccounts: accounts.values.toList(),
        categoryGroups: groups.values.toList(),
        categories: categories.values.toList(),
        labels: labels,
        reminders: const [],
        reminderLabels: const [],
        transactions: transactions,
        transactionLabels: transactionLabels,
      ),
      report: BluecoinsImportReport(
        userVersion: source.userVersion,
        skipped: skipped,
        notes: noted,
      ),
    );
  }

  void _assetsAccounts() {
    final groupOfType = {
      for (final t in source.accountTypes)
        _int(t['accountTypeTableID']): _int(t['accountingGroupID']),
    };
    for (final a in source.accounts) {
      final id = _int(a['accountsTableID']);
      final typeId = _int(a['accountTypeID']);
      // Ids -1 and 0, type 0: the "(No account)" placeholders.
      if (id == null || id == -1 || id == 0 || typeId == 0) continue;
      final name = _name(a['accountName']);
      final currency = _text(a['accountCurrency']).trim().toUpperCase();
      if (name == null || !_currency.hasMatch(currency)) {
        skip(BluecoinsSkipReason.invalid);
        continue;
      }
      var type = _assetsAccountTypes[typeId];
      if (type == null) {
        note(BluecoinsNote.unknownAssetsAccountType);
        type = groupOfType[typeId] == 2
            ? AssetsAccountType.otherLiability
            : AssetsAccountType.otherAsset;
      }
      final creditLimit = _int(a['creditLimit']);
      accounts[id] = AssetsAccountTableRow(
        id: newId(),
        name: name,
        type: type,
        currency: currency,
        isHidden: _int(a['accountHidden']) == 1,
        isFavorite: false,
        excludeFromNetWorth: false,
        creditLimit:
            creditLimit != null && creditLimit > 0 && _money(creditLimit)
            ? creditLimit
            : null,
        sortOrder: accounts.length,
        notes: '',
        createdAt: now,
        updatedAt: now,
      );
    }
  }

  /// Parents become groups and children categories, each in its own id
  /// space. Budgets are reported: their period codes are not confirmed.
  void _categories() {
    bool budgeted(Object? amount, Object? enabled) =>
        (_int(amount) ?? 0) > 0 && _int(enabled) == 1;

    for (final p in source.parentCategories) {
      final id = _int(p['parentCategoryTableID']);
      final kind = _categoryKinds[_int(p['categoryGroupID'])];
      // The system groups ("new account", "transfer") hold nothing to import.
      if (id == null || kind == null) continue;
      final name = _name(p['parentCategoryName']);
      if (name == null) {
        skip(BluecoinsSkipReason.invalid);
        continue;
      }
      if (budgeted(
        p['budgetAmountCategoryParent'],
        p['budgetEnabledCategoryParent'],
      )) {
        skip(BluecoinsSkipReason.budget);
      }
      groups[id] = CategoryGroupTableRow(
        id: newId(),
        name: name,
        kind: kind,
        isHidden: false,
        sortOrder: groups.length,
        budgetAmount: null,
        budgetPeriod: null,
        budgetRollover: false,
      );
    }

    final systemParents = {
      for (final p in source.parentCategories)
        if (!_categoryKinds.containsKey(_int(p['categoryGroupID'])))
          _int(p['parentCategoryTableID']),
    };
    for (final c in source.childCategories) {
      final id = _int(c['categoryTableID']);
      final parentId = _int(c['parentCategoryID']);
      if (id == null || systemParents.contains(parentId)) continue;
      final group = groups[parentId];
      final name = _name(c['childCategoryName']);
      if (group == null || name == null) {
        skip(BluecoinsSkipReason.invalid);
        continue;
      }
      if (budgeted(c['budgetAmount'], c['budgetEnabledCategoryChild'])) {
        skip(BluecoinsSkipReason.budget);
      }
      categories[id] = CategoryTableRow(
        id: newId(),
        name: name,
        groupId: group.id,
        icon: BluecoinsMapper.icon(_text(c['childCategoryIcon'])),
        color: categoryColors[categories.length % categoryColors.length],
        isHidden: false,
        sortOrder: categories.length,
        budgetAmount: null,
        budgetPeriod: null,
        budgetRollover: false,
      );
    }
  }

  void _transactions() {
    final titles = {
      for (final i in source.items)
        _int(i['itemTableID']): _text(i['itemName']),
    };
    final kinds = {for (final g in groups.values) g.id: g.kind};
    final legs = <_Leg>[];

    for (final t in source.transactions) {
      final state = _int(t['deletedTransaction']);
      if (state == _deleted) {
        skip(BluecoinsSkipReason.deleted);
        continue;
      }
      if (state != _active) {
        skip(BluecoinsSkipReason.unknownType);
        continue;
      }
      final reminder = _int(t['reminderTransaction']);
      if (reminder != null && reminder != 0) {
        skip(BluecoinsSkipReason.reminder);
        continue;
      }
      final type = switch (_int(t['transactionTypeID'])) {
        1 || 2 => TransactionType.openingBalance,
        3 => TransactionType.expense,
        4 => TransactionType.income,
        5 => TransactionType.transfer,
        _ => null,
      };
      if (type == null) {
        skip(BluecoinsSkipReason.unknownType);
        continue;
      }
      final account = accounts[_int(t['accountID'])];
      if (account == null) {
        skip(BluecoinsSkipReason.missingAssetsAccount);
        continue;
      }
      final id = _int(t['transactionsTableID']);
      final amount = _int(t['amount']);
      final occurredAt = parseWallClock(_text(t['date']));
      if (id == null ||
          amount == null ||
          !_money(amount) ||
          occurredAt == null) {
        skip(BluecoinsSkipReason.invalid);
        continue;
      }
      final currency = _text(t['transactionCurrency']).trim().toUpperCase();
      if (currency.isNotEmpty && currency != account.currency) {
        skip(BluecoinsSkipReason.otherCurrency);
        continue;
      }
      if ((_int(t['newSplitTransactionID']) ?? 0) != 0) {
        note(BluecoinsNote.splitTransaction);
      }
      final title = titles[_int(t['itemID'])] ?? '';
      final notes = _text(t['notes']);

      if (type == TransactionType.transfer) {
        legs.add(
          _Leg(
            id: id,
            group: _int(t['transferGroupID']),
            pair: _int(t['uidPairID']),
            reference: _int(t['accountReference']),
            amount: amount,
            account: account,
            occurredAt: occurredAt,
            title: title,
            notes: notes,
          ),
        );
        continue;
      }
      // Bluecoins writes one for every new assets account, even at zero.
      if (type == TransactionType.openingBalance && amount == 0) continue;

      String? categoryId;
      if (type != TransactionType.openingBalance) {
        final category = categories[_int(t['categoryID'])];
        final wanted = type == TransactionType.income
            ? CategoryKind.income
            : CategoryKind.expense;
        if (category != null && kinds[category.groupId] == wanted) {
          categoryId = category.id;
        } else {
          note(BluecoinsNote.uncategorized);
        }
      }
      transactions.add(
        _row(
          id,
          type: type,
          occurredAt: occurredAt,
          title: title,
          amount: amount,
          account: account,
          categoryId: categoryId,
          notes: notes,
        ),
      );
    }
    _transfers(legs);
  }

  /// Both legs of a transfer share `transferGroupID`; without one, legs
  /// whose `uidPairID` point at each other pair up.
  void _transfers(List<_Leg> legs) {
    final byGroup = <String, List<_Leg>>{};
    for (final leg in legs) {
      final key = leg.group != null
          ? 'group ${leg.group}'
          : 'pair ${[leg.id, leg.pair ?? leg.id]..sort()}';
      (byGroup[key] ??= []).add(leg);
    }
    for (final group in byGroup.values) {
      final from = _pick(group, _sourceLeg, (amount) => amount < 0);
      final to = _pick(group, _destinationLeg, (amount) => amount > 0);
      if (group.length != 2 ||
          from == null ||
          to == null ||
          identical(from, to) ||
          from.account.id == to.account.id) {
        skip(BluecoinsSkipReason.orphanTransfer);
        continue;
      }
      final amount = from.amount.abs();
      final received = to.amount.abs();
      final between = from.account.currency != to.account.currency;
      // Our transfers carry one amount unless currencies differ.
      if (amount == 0 || received == 0 || (!between && amount != received)) {
        skip(BluecoinsSkipReason.invalid);
        continue;
      }
      final row = _row(
        from.id,
        type: TransactionType.transfer,
        occurredAt: from.occurredAt,
        title: from.title.isNotEmpty ? from.title : to.title,
        amount: amount,
        account: from.account,
        toAccount: to.account,
        toAmount: between ? received : null,
        notes: from.notes.isNotEmpty ? from.notes : to.notes,
      );
      transactionIds[to.id] = row.id;
      transactions.add(row);
    }
  }

  /// The leg marked with [reference], or else the only one whose amount
  /// passes [sign].
  _Leg? _pick(List<_Leg> group, int reference, bool Function(int) sign) {
    final marked = group.where((l) => l.reference == reference);
    if (marked.length == 1) return marked.single;
    final signed = group.where((l) => sign(l.amount));
    return signed.length == 1 ? signed.single : null;
  }

  TransactionTableRow _row(
    int sourceId, {
    required TransactionType type,
    required DateTime occurredAt,
    required String title,
    required int amount,
    required AssetsAccountTableRow account,
    AssetsAccountTableRow? toAccount,
    int? toAmount,
    String? categoryId,
    required String notes,
  }) {
    final row = TransactionTableRow(
      id: newId(),
      type: type,
      occurredAt: occurredAt,
      title: title,
      amount: amount,
      assetsAccountId: account.id,
      toAssetsAccountId: toAccount?.id,
      toAmount: toAmount,
      categoryId: categoryId,
      currency: account.currency,
      exchangeRate: null,
      notes: notes,
      reminderId: null,
      deletedAt: null,
      createdAt: now,
      updatedAt: now,
    );
    transactionIds[sourceId] = row.id;
    return row;
  }

  /// A row without a transaction defines a label; one with a transaction
  /// assigns it. Names match ignoring case and surrounding spaces.
  void _labels() {
    final byName = <String, LabelTableRow>{};
    final assigned = <String, TransactionLabelTableRow>{};
    for (final l in source.labels) {
      final name = _name(l['labelName']);
      if (name == null) continue;
      final label = byName[name.toLowerCase()] ??= LabelTableRow(
        id: newId(),
        name: name,
      );
      final transactionId = transactionIds[_int(l['transactionIDLabels'])];
      if (transactionId != null) {
        // A transfer's two legs may carry the same label.
        assigned['$transactionId ${label.id}'] = TransactionLabelTableRow(
          transactionId: transactionId,
          labelId: label.id,
        );
      }
    }
    labels.addAll(byName.values);
    transactionLabels.addAll(assigned.values);
  }

  /// `SETTINGSTABLE` row 1, or else the first assets account's currency.
  Map<String, String> _mainCurrency() {
    for (final s in source.settings) {
      if (_int(s['settingsTableID']) != 1) continue;
      final currency = _text(s['defaultSettings']).trim().toUpperCase();
      if (_currency.hasMatch(currency)) {
        return {SettingKeys.mainCurrency: currency};
      }
    }
    return {
      if (accounts.values.firstOrNull case final first?)
        SettingKeys.mainCurrency: first.currency,
    };
  }
}

class _Leg {
  const _Leg({
    required this.id,
    required this.group,
    required this.pair,
    required this.reference,
    required this.amount,
    required this.account,
    required this.occurredAt,
    required this.title,
    required this.notes,
  });

  final int id;
  final int? group;
  final int? pair;
  final int? reference;
  final int amount;
  final AssetsAccountTableRow account;
  final DateTime occurredAt;
  final String title;
  final String notes;
}

/// SQLite integers; whole reals too, since the columns have no strict type.
int? _int(Object? value) => switch (value) {
  final int v => v,
  final double v when v == v.truncateToDouble() && v.isFinite => v.toInt(),
  _ => null,
};

String _text(Object? value) => value is String ? value : '';

/// Trimmed and cut to the 100 characters the tables allow; `null` if empty.
String? _name(Object? value) {
  final name = _text(value).trim();
  if (name.isEmpty) return null;
  return name.length > 100 ? name.substring(0, 100) : name;
}

bool _money(int micros) => micros.abs() <= maxMoney;
