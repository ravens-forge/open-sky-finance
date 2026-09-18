import 'package:drift/drift.dart';

import '../../enums/reminder_frequency.dart';
import '../../enums/transaction_type.dart';
import '../../models/money.dart';
import '../../models/reminder_schedule.dart';
import '../../models/timestamps.dart';
import '../../models/transfer_destination.dart';
import '../../models/reminder.dart';
import 'assets_accounts_table.dart';
import 'categories_table.dart';
import 'wall_clock_converter.dart';

@UseRowClass(ReminderTableRow, generateInsertable: true)
@TableIndex(name: 'reminders_next_due_at', columns: {#nextDueAt})
class RemindersTable extends Table {
  @override
  String get tableName => 'reminders';

  TextColumn get id => text()();
  TextColumn get type => textEnum<TransactionType>()();
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
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get frequency => textEnum<ReminderFrequency>()();
  IntColumn get interval => integer().withDefault(const Constant(1))();
  TextColumn get startDate => text().map(const WallClockConverter())();
  TextColumn get nextDueAt =>
      text().map(const WallClockConverter()).nullable()();
  TextColumn get endDate => text().map(const WallClockConverter()).nullable()();
  IntColumn get remainingOccurrences => integer().nullable()();
  BoolColumn get autoPost => boolean().withDefault(const Constant(false))();
  BoolColumn get notify => boolean().withDefault(const Constant(false))();
  BoolColumn get isPaused => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
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
    "CHECK (type <> 'openingBalance')",
    'CHECK (interval >= 1)',
  ];
}

class ReminderTableRow {
  const ReminderTableRow({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    required this.assetsAccountId,
    required this.toAssetsAccountId,
    required this.toAmount,
    required this.categoryId,
    required this.currency,
    required this.notes,
    required this.frequency,
    required this.interval,
    required this.startDate,
    required this.nextDueAt,
    required this.endDate,
    required this.remainingOccurrences,
    required this.autoPost,
    required this.notify,
    required this.isPaused,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReminderTableRow.fromDomain(Reminder r) => ReminderTableRow(
    id: r.id,
    type: r.type,
    title: r.title,
    amount: r.amount.micros,
    assetsAccountId: r.assetsAccountId,
    toAssetsAccountId: r.transfer?.assetsAccountId,
    toAmount: r.transfer?.amountReceived,
    categoryId: r.categoryId,
    currency: r.amount.currency,
    notes: r.notes,
    frequency: r.schedule.frequency,
    interval: r.schedule.interval,
    startDate: r.schedule.startDate,
    nextDueAt: r.schedule.nextDueAt,
    endDate: r.schedule.endDate,
    remainingOccurrences: r.schedule.remainingOccurrences,
    autoPost: r.autoPost,
    notify: r.notify,
    isPaused: r.isPaused,
    sortOrder: r.sortOrder,
    createdAt: r.timestamps.createdAt,
    updatedAt: r.timestamps.updatedAt,
  );

  final String id;
  final TransactionType type;
  final String title;
  final int amount;
  final String assetsAccountId;
  final String? toAssetsAccountId;
  final int? toAmount;
  final String? categoryId;
  final String currency;
  final String notes;
  final ReminderFrequency frequency;
  final int interval;
  final DateTime startDate;
  final DateTime? nextDueAt;
  final DateTime? endDate;
  final int? remainingOccurrences;
  final bool autoPost;
  final bool notify;
  final bool isPaused;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  Reminder toDomain() => Reminder(
    id: id,
    type: type,
    title: title,
    amount: Money(amount, currency),
    assetsAccountId: assetsAccountId,
    transfer: toAssetsAccountId == null
        ? null
        : TransferDestination(
            assetsAccountId: toAssetsAccountId!,
            amountReceived: toAmount,
          ),
    categoryId: categoryId,
    notes: notes,
    schedule: ReminderSchedule(
      frequency: frequency,
      interval: interval,
      startDate: startDate,
      nextDueAt: nextDueAt,
      endDate: endDate,
      remainingOccurrences: remainingOccurrences,
    ),
    autoPost: autoPost,
    notify: notify,
    isPaused: isPaused,
    sortOrder: sortOrder,
    timestamps: Timestamps(createdAt: createdAt, updatedAt: updatedAt),
  );
}
