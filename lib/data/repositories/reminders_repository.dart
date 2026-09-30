import 'package:drift/drift.dart';

import '../../core/dates/wall_clock.dart';
import '../../core/ids.dart';
import '../../core/result.dart';
import '../database/app_database.dart';
import '../database/tables/reminder_labels_table.dart';
import '../database/tables/reminders_table.dart';
import '../enums/reminder_frequency.dart';
import '../models/reminder.dart';
import '../models/reminder_draft.dart';
import '../models/reminder_schedule.dart';
import '../models/transaction_draft.dart';
import 'repository_data_error.dart';

part 'reminders_repository.g.dart';

@DriftAccessor(tables: [RemindersTable, ReminderLabelsTable])
class RemindersRepository extends DatabaseAccessor<AppDatabase>
    with _$RemindersRepositoryMixin {
  RemindersRepository(super.attachedDatabase);

  /// The next [limit] due reminders, overdue first; paused and finished ones
  /// are left out.
  Stream<List<Reminder>> watchUpcoming(int limit) =>
      (select(remindersTable)
            ..where((r) => r.nextDueAt.isNotNull() & r.isPaused.equals(false))
            ..orderBy([
              (r) => OrderingTerm(expression: r.nextDueAt),
              (r) => OrderingTerm(expression: r.sortOrder),
            ])
            ..limit(limit))
          .map((r) => r.toDomain())
          .watch();

  /// Every reminder, next due first and finished ones last. Its `status`
  /// tells active, paused and finished apart, and its schedule gives the
  /// occurrences of a period.
  Stream<List<Reminder>> watchAll() =>
      (select(remindersTable)..orderBy([
            (r) =>
                OrderingTerm(expression: r.nextDueAt, nulls: NullsOrder.last),
            (r) => OrderingTerm(expression: r.sortOrder),
            (r) => OrderingTerm(expression: r.title),
          ]))
          .map((r) => r.toDomain())
          .watch();

  SimpleSelectStatement<$RemindersTableTable, ReminderTableRow> _byId(
    String id,
  ) => select(remindersTable)..where((r) => r.id.equals(id));

  Future<Reminder?> findById(String id) =>
      _byId(id).map((r) => r.toDomain()).getSingleOrNull();

  Stream<Reminder?> watchById(String id) =>
      _byId(id).map((r) => r.toDomain()).watchSingleOrNull();

  Future<List<String>> labelIdsOf(String reminderId) => (select(
    reminderLabelsTable,
  )..where((l) => l.reminderId.equals(reminderId))).map((l) => l.labelId).get();

  /// Validates the template like a transaction, then inserts or updates the
  /// row and its labels in one database transaction. A schedule whose end
  /// conditions are already met is saved finished. Returns the id.
  Future<Result<String, RepositoryDataError>> save(
    ReminderDraft draft,
  ) => transaction(() async {
    final once = draft.schedule.frequency == ReminderFrequency.once;
    if (draft.schedule.interval < 1 ||
        (draft.schedule.remainingOccurrences ?? 0) < 0) {
      return const Err(RepositoryDataError.invalidSchedule);
    }
    final (row, error) = await attachedDatabase.transactionsRepository.validate(
      draft.template,
    );
    if (error != null) return Err(error);

    // A single occurrence has nothing to repeat or end.
    final schedule = ReminderSchedule(
      frequency: draft.schedule.frequency,
      interval: once ? 1 : draft.schedule.interval,
      startDate: draft.schedule.startDate,
      nextDueAt: draft.schedule.nextDueAt,
      endDate: once ? null : draft.schedule.endDate,
      remainingOccurrences: once ? null : draft.schedule.remainingOccurrences,
    ).normalized();
    final now = DateTime.now().toUtc();
    final id = draft.id ?? newId();
    final columns = RemindersTableCompanion(
      type: row!.type,
      title: row.title,
      amount: row.amount,
      assetsAccountId: row.assetsAccountId,
      toAssetsAccountId: row.toAssetsAccountId,
      toAmount: row.toAmount,
      categoryId: row.categoryId,
      currency: row.currency,
      notes: row.notes,
      frequency: Value(schedule.frequency),
      interval: Value(schedule.interval),
      startDate: Value(schedule.startDate),
      nextDueAt: Value(schedule.nextDueAt),
      endDate: Value(schedule.endDate),
      remainingOccurrences: Value(schedule.remainingOccurrences),
      autoPost: Value(draft.autoPost),
      isPaused: Value(draft.isPaused),
      updatedAt: Value(now),
    );
    if (draft.id == null) {
      await into(remindersTable)
          .insert(columns.copyWith(id: Value(id), createdAt: Value(now)));
    } else {
      final updated = await (update(
        remindersTable,
      )..where((r) => r.id.equals(id))).write(columns);
      if (updated == 0) return const Err(RepositoryDataError.notFound);
    }

    await (delete(
      reminderLabelsTable,
    )..where((l) => l.reminderId.equals(id))).go();
    await batch(
      (b) => b.insertAll(reminderLabelsTable, [
        for (final labelId in draft.template.labelIds.toSet())
          ReminderLabelsTableCompanion.insert(reminderId: id, labelId: labelId),
      ]),
    );
    return Ok(id);
  });

  /// "Repeat" of the transaction editor: a reminder of [draft] every
  /// [frequency] from its date. Dated before [tomorrow], that first
  /// occurrence is recorded as well, so the reminder waits for the next one;
  /// a future date creates only the reminder. Returns the reminder's id.
  Future<Result<String, RepositoryDataError>> saveRepeating(
    TransactionDraft draft,
    ReminderFrequency frequency, {
    required DateTime tomorrow,
  }) => transaction(() async {
    final saved = await save(
      ReminderDraft(
        template: draft,
        schedule: ReminderSchedule(
          frequency: frequency,
          startDate: draft.occurredAt,
          nextDueAt: draft.occurredAt,
        ),
      ),
    );
    if (saved case Ok(value: final id)
        when draft.occurredAt.isBefore(tomorrow)) {
      if (await record(id) case Err(:final error)) return Err(error);
    }
    return saved;
  });

  /// Its recorded transactions are kept, without it.
  Future<int> remove(String id) =>
      (delete(remindersTable)..where((r) => r.id.equals(id))).go();

  Future<void> _writeSchedule(String id, ReminderSchedule schedule) =>
      (update(remindersTable)..where((r) => r.id.equals(id))).write(
        RemindersTableCompanion(
          nextDueAt: Value(schedule.nextDueAt),
          remainingOccurrences: Value(schedule.remainingOccurrences),
        ),
      );

  /// Records the next occurrence: in one database transaction, inserts the
  /// template as a transaction dated on the due date and advances the
  /// schedule. Returns the transaction's id.
  Future<Result<String, RepositoryDataError>> record(String id) =>
      transaction(() async {
        final reminder = await findById(id);
        final due = reminder?.schedule.nextDueAt;
        if (reminder == null || due == null) {
          return const Err(RepositoryDataError.notFound);
        }
        final result = await attachedDatabase.transactionsRepository.save(
          TransactionDraft(
            type: reminder.type,
            occurredAt: due,
            amount: reminder.amount.micros,
            assetsAccountId: reminder.assetsAccountId,
            toAssetsAccountId: reminder.transfer?.assetsAccountId,
            toAmount: reminder.transfer?.amountReceived,
            categoryId: reminder.categoryId,
            title: reminder.title,
            notes: reminder.notes,
            labelIds: await labelIdsOf(id),
            reminderId: id,
          ),
        );
        if (result is Ok) {
          await _writeSchedule(id, reminder.schedule.advanced());
        }
        return result;
      });

  /// Undo of [record]: deletes the recorded transaction and puts the
  /// schedule back as it was in [before].
  Future<void> undoRecord(String transactionId, Reminder before) =>
      transaction(() async {
        await attachedDatabase.transactionsRepository.deletePermanently(
          transactionId,
        );
        await _writeSchedule(before.id, before.schedule);
      });

  /// Moves on to the following occurrence without recording this one.
  Future<void> skip(String id) => transaction(() async {
    final reminder = await findById(id);
    if (reminder != null) {
      await _writeSchedule(id, reminder.schedule.advanced());
    }
  });

  /// Records every occurrence due before [tomorrow] of the automatic
  /// reminders that are not paused, all in one database transaction. Returns
  /// how many were recorded.
  Future<int> postDue(DateTime tomorrow) async {
    final due = select(remindersTable)
      ..where(
        (r) =>
            r.autoPost.equals(true) &
            r.isPaused.equals(false) &
            r.nextDueAt.isSmallerThanValue(formatWallClock(tomorrow)),
      );
    // Nothing due is the usual case: no write transaction for it.
    if ((await due.get()).isEmpty) return 0;
    return transaction(() async {
      var recorded = 0;
      for (final row in await due.get()) {
        var next = row.nextDueAt;
        // A reminder that can no longer be recorded (its assets accounts
        // changed currency) stays due instead of looping.
        while (next != null && next.isBefore(tomorrow)) {
          if (await record(row.id) is! Ok) break;
          recorded++;
          next = (await findById(row.id))?.schedule.nextDueAt;
        }
      }
      return recorded;
    });
  }
}
