import 'package:drift/drift.dart';

import '../../enums/transaction_type.dart';
import '../../models/money.dart';
import '../../models/timestamps.dart';
import '../../models/transfer_destination.dart';
import '../../models/transaction.dart';
import 'assets_accounts_table.dart';
import 'categories_table.dart';
import 'reminders_table.dart';
import 'wall_clock_converter.dart';

@UseRowClass(TransactionTableRow, generateInsertable: true)
@TableIndex(name: 'transactions_occurred_at', columns: {#occurredAt})
@TableIndex(
  name: 'transactions_assets_account_occurred_at',
  columns: {#assetsAccountId, #occurredAt},
)
@TableIndex(
  name: 'transactions_to_assets_account_id',
  columns: {#toAssetsAccountId},
)
@TableIndex(name: 'transactions_category_id', columns: {#categoryId})
@TableIndex(name: 'transactions_deleted_at', columns: {#deletedAt})
class TransactionsTable extends Table {
  @override
  String get tableName => 'transactions';

  TextColumn get id => text()();
  TextColumn get type => textEnum<TransactionType>()();
  TextColumn get occurredAt => text().map(const WallClockConverter())();
  TextColumn get title => text().withDefault(const Constant(''))();
  IntColumn get amount => integer()();
  TextColumn get assetsAccountId => text().references(
    AssetsAccountsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get toAssetsAccountId => text().nullable().references(
    AssetsAccountsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get toAmount => integer().nullable()();
  TextColumn get categoryId => text().nullable().references(
    CategoriesTable,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get currency => text()();
  TextColumn get exchangeRate => text().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get reminderId => text().nullable().references(
    RemindersTable,
    #id,
    onDelete: KeyAction.setNull,
  )();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (type <> 'transfer' OR (to_assets_account_id IS NOT NULL "
        'AND to_assets_account_id <> assets_account_id AND amount > 0 '
        'AND category_id IS NULL AND (to_amount IS NULL OR to_amount > 0)))',
    "CHECK (type = 'transfer' OR (to_assets_account_id IS NULL "
        'AND to_amount IS NULL))',
    "CHECK (currency GLOB '[A-Z][A-Z][A-Z]')",
    "CHECK (type = 'transfer' OR exchange_rate IS NULL)",
    "CHECK (type <> 'openingBalance' OR category_id IS NULL)",
  ];
}

class TransactionTableRow {
  const TransactionTableRow({
    required this.id,
    required this.type,
    required this.occurredAt,
    required this.title,
    required this.amount,
    required this.assetsAccountId,
    required this.toAssetsAccountId,
    required this.toAmount,
    required this.categoryId,
    required this.currency,
    required this.exchangeRate,
    required this.notes,
    required this.reminderId,
    required this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransactionTableRow.fromDomain(Transaction t) => TransactionTableRow(
    id: t.id,
    type: t.type,
    occurredAt: t.occurredAt,
    title: t.title,
    amount: t.amount.micros,
    assetsAccountId: t.assetsAccountId,
    toAssetsAccountId: t.transfer?.assetsAccountId,
    toAmount: t.transfer?.amountReceived,
    categoryId: t.categoryId,
    currency: t.amount.currency,
    exchangeRate: t.transfer?.exchangeRate,
    notes: t.notes,
    reminderId: t.reminderId,
    deletedAt: t.deletedAt,
    createdAt: t.timestamps.createdAt,
    updatedAt: t.timestamps.updatedAt,
  );

  final String id;
  final TransactionType type;
  final DateTime occurredAt;
  final String title;
  final int amount;
  final String assetsAccountId;
  final String? toAssetsAccountId;
  final int? toAmount;
  final String? categoryId;
  final String currency;
  final String? exchangeRate;
  final String notes;
  final String? reminderId;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction toDomain() => Transaction(
    id: id,
    type: type,
    occurredAt: occurredAt,
    title: title,
    amount: Money(amount, currency),
    assetsAccountId: assetsAccountId,
    transfer: toAssetsAccountId == null
        ? null
        : TransferDestination(
            assetsAccountId: toAssetsAccountId!,
            amountReceived: toAmount,
            exchangeRate: exchangeRate,
          ),
    categoryId: categoryId,
    notes: notes,
    reminderId: reminderId,
    deletedAt: deletedAt,
    timestamps: Timestamps(createdAt: createdAt, updatedAt: updatedAt),
  );
}
