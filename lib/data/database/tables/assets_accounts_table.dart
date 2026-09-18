import 'package:drift/drift.dart';

import '../../enums/assets_account_type.dart';
import '../../models/assets_account.dart';
import '../../models/timestamps.dart';

@UseRowClass(AssetsAccountTableRow, generateInsertable: true)
class AssetsAccountsTable extends Table {
  @override
  String get tableName => 'assets_accounts';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => textEnum<AssetsAccountType>()();
  TextColumn get currency => text()();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get excludeFromNetWorth =>
      boolean().withDefault(const Constant(false))();
  IntColumn get creditLimit => integer().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (length(name) BETWEEN 1 AND 100)',
    "CHECK (currency GLOB '[A-Z][A-Z][A-Z]')",
  ];
}

class AssetsAccountTableRow {
  const AssetsAccountTableRow({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.isHidden,
    required this.isFavorite,
    required this.excludeFromNetWorth,
    required this.creditLimit,
    required this.sortOrder,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AssetsAccountTableRow.fromDomain(AssetsAccount a) =>
      AssetsAccountTableRow(
        id: a.id,
        name: a.name,
        type: a.type,
        currency: a.currency,
        isHidden: a.isHidden,
        isFavorite: a.isFavorite,
        excludeFromNetWorth: a.excludeFromNetWorth,
        creditLimit: a.creditLimit,
        sortOrder: a.sortOrder,
        notes: a.notes,
        createdAt: a.timestamps.createdAt,
        updatedAt: a.timestamps.updatedAt,
      );

  final String id;
  final String name;
  final AssetsAccountType type;
  final String currency;
  final bool isHidden;
  final bool isFavorite;
  final bool excludeFromNetWorth;
  final int? creditLimit;
  final int sortOrder;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  AssetsAccount toDomain() => AssetsAccount(
    id: id,
    name: name,
    type: type,
    currency: currency,
    isHidden: isHidden,
    isFavorite: isFavorite,
    excludeFromNetWorth: excludeFromNetWorth,
    creditLimit: creditLimit,
    sortOrder: sortOrder,
    notes: notes,
    timestamps: Timestamps(createdAt: createdAt, updatedAt: updatedAt),
  );
}
