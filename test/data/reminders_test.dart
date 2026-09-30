import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/enums/reminder_frequency.dart';
import 'package:open_sky_finance/data/enums/reminder_status.dart';
import 'package:open_sky_finance/data/enums/transaction_type.dart';
import 'package:open_sky_finance/data/models/reminder.dart';
import 'package:open_sky_finance/data/models/reminder_draft.dart';
import 'package:open_sky_finance/data/models/reminder_schedule.dart';
import 'package:open_sky_finance/data/models/transaction.dart';
import 'package:open_sky_finance/data/models/transaction_draft.dart';
import 'package:open_sky_finance/data/repositories/repository_data_error.dart';

import 'test_db.dart';

ReminderSchedule _schedule(
  ReminderFrequency frequency,
  DateTime start, {
  int interval = 1,
  DateTime? endDate,
  int? times,
}) => ReminderSchedule(
  frequency: frequency,
  interval: interval,
  startDate: start,
  nextDueAt: start,
  endDate: endDate,
  remainingOccurrences: times,
);

void main() {
  group('occurrences', () {
    test('monthly keeps the start day, clamped to the month end', () {
      expect(
        _schedule(
          ReminderFrequency.monthly,
          DateTime(2026, 1, 31, 9, 30),
        ).upcoming.take(5),
        [
          DateTime(2026, 1, 31, 9, 30),
          DateTime(2026, 2, 28, 9, 30),
          DateTime(2026, 3, 31, 9, 30),
          DateTime(2026, 4, 30, 9, 30),
          DateTime(2026, 5, 31, 9, 30),
        ],
      );
    });

    test('leap years: 29 February, and a yearly one born on it', () {
      expect(
        _schedule(
          ReminderFrequency.monthly,
          DateTime(2028, 1, 30),
        ).upcoming.elementAt(1),
        DateTime(2028, 2, 29),
      );
      expect(
        _schedule(
          ReminderFrequency.yearly,
          DateTime(2028, 2, 29),
        ).upcoming.take(5),
        [
          DateTime(2028, 2, 29),
          DateTime(2029, 2, 28),
          DateTime(2030, 2, 28),
          DateTime(2031, 2, 28),
          DateTime(2032, 2, 29),
        ],
      );
    });

    test('intervals: every N days, weeks, months and years', () {
      DateTime second(ReminderFrequency frequency, int interval) => _schedule(
        frequency,
        DateTime(2026, 11, 30),
        interval: interval,
      ).upcoming.elementAt(1);
      expect(second(ReminderFrequency.daily, 3), DateTime(2026, 12, 3));
      expect(second(ReminderFrequency.weekly, 2), DateTime(2026, 12, 14));
      // Over the year end, and into a 28-day February.
      expect(second(ReminderFrequency.monthly, 3), DateTime(2027, 2, 28));
      expect(second(ReminderFrequency.yearly, 2), DateTime(2028, 11, 30));
    });

    test('once happens once', () {
      final once = _schedule(ReminderFrequency.once, DateTime(2026, 9, 17));
      expect(once.upcoming, [DateTime(2026, 9, 17)]);
      expect(once.advanced().nextDueAt, isNull);
    });

    test('the end date is inclusive', () {
      expect(
        _schedule(
          ReminderFrequency.monthly,
          DateTime(2026, 9, 25, 9),
          endDate: DateTime(2026, 11, 25),
        ).upcoming,
        [
          DateTime(2026, 9, 25, 9),
          DateTime(2026, 10, 25, 9),
          DateTime(2026, 11, 25, 9),
        ],
      );
    });

    test('a number of times counts down to finished', () {
      var schedule = _schedule(
        ReminderFrequency.weekly,
        DateTime(2026, 9, 17),
        times: 2,
      );
      expect(schedule.upcoming, [DateTime(2026, 9, 17), DateTime(2026, 9, 24)]);
      schedule = schedule.advanced();
      expect(schedule.remainingOccurrences, 1);
      schedule = schedule.advanced();
      expect(schedule.remainingOccurrences, 0);
      expect(schedule.nextDueAt, isNull);
      expect(schedule.advanced().remainingOccurrences, 0);
    });

    test('a period takes its occurrences only', () {
      expect(
        _schedule(
          ReminderFrequency.weekly,
          DateTime(2026, 9, 1),
        ).occurrencesIn(DateTime(2026, 9, 8), DateTime(2026, 9, 22)),
        [DateTime(2026, 9, 8), DateTime(2026, 9, 15)],
      );
    });
  });

  group('repository', () {
    late AppDatabase db;
    late String bank;
    late String savings;
    late String usd;
    late String groceries;
    late String label;

    setUp(() async {
      db = testDb();
      bank = await addAssetsAccount(db, 'Bank');
      savings = await addAssetsAccount(db, 'Savings');
      usd = await addAssetsAccount(db, 'Dollars', currency: 'USD');
      groceries = await addCategory(
        db,
        'Groceries',
        groupId: await addCategoryGroup(db, 'Food'),
      );
      label = ok(await db.labelsRepository.save(name: 'home'));
    });

    ReminderDraft draft({
      String? id,
      ReminderFrequency frequency = ReminderFrequency.monthly,
      DateTime? start,
      DateTime? endDate,
      int? times,
      int interval = 1,
      bool autoPost = false,
      bool isPaused = false,
      TransactionDraft? template,
    }) => ReminderDraft(
      id: id,
      template:
          template ??
          TransactionDraft(
            type: TransactionType.expense,
            occurredAt: DateTime(2000),
            amount: -m(40),
            assetsAccountId: bank,
            categoryId: groceries,
            title: 'Market',
            notes: 'weekly shop',
            labelIds: [label],
          ),
      schedule: _schedule(
        frequency,
        start ?? DateTime(2026, 9, 15),
        interval: interval,
        endDate: endDate,
        times: times,
      ),
      autoPost: autoPost,
      isPaused: isPaused,
    );

    Future<Reminder> reminder(String id) async =>
        (await db.remindersRepository.findById(id))!;

    Future<List<Transaction>> recorded(String id) =>
        db.transactionsRepository.watchByReminder(id).first;

    test('save writes the template, its labels and the schedule', () async {
      final id = ok(await db.remindersRepository.save(draft(times: 3)));
      final saved = await reminder(id);
      expect(saved.title, 'Market');
      expect(saved.amount.micros, -m(40));
      expect(saved.amount.currency, 'EUR');
      expect(saved.categoryId, groceries);
      expect(saved.schedule.nextDueAt, DateTime(2026, 9, 15));
      expect(saved.schedule.remainingOccurrences, 3);
      expect(saved.status, ReminderStatus.active);
      expect(await db.remindersRepository.labelIdsOf(id), [label]);

      // An update replaces the labels and can pause it.
      ok(
        await db.remindersRepository.save(
          draft(
            id: id,
            isPaused: true,
            template: TransactionDraft(
              type: TransactionType.expense,
              occurredAt: DateTime(2000),
              amount: -m(45),
              assetsAccountId: bank,
              title: 'Market',
            ),
          ),
        ),
      );
      expect((await reminder(id)).status, ReminderStatus.paused);
      expect((await reminder(id)).amount.micros, -m(45));
      expect(await db.remindersRepository.labelIdsOf(id), isEmpty);
    });

    test('save shares the invariants of transactions', () async {
      TransactionDraft transfer({
        String? to,
        int? toAmount,
        String? category,
      }) => TransactionDraft(
        type: TransactionType.transfer,
        occurredAt: DateTime(2000),
        amount: m(100),
        assetsAccountId: bank,
        toAssetsAccountId: to,
        toAmount: toAmount,
        categoryId: category,
      );
      Future<RepositoryDataError?> save(TransactionDraft template) async =>
          err(await db.remindersRepository.save(draft(template: template)));

      expect(
        await save(transfer(to: bank)),
        RepositoryDataError.transferToSameAssetsAccount,
      );
      expect(
        await save(transfer(to: savings, category: groceries)),
        RepositoryDataError.categoryNotAllowed,
      );
      expect(
        await save(transfer(to: usd)),
        RepositoryDataError.toAmountRequired,
      );
      expect(await save(transfer(to: usd, toAmount: m(108))), isNull);
      expect(
        await save(
          TransactionDraft(
            type: TransactionType.income,
            occurredAt: DateTime(2000),
            amount: m(10),
            assetsAccountId: bank,
            categoryId: groceries,
          ),
        ),
        RepositoryDataError.categoryKindMismatch,
      );
      expect(
        err(await db.remindersRepository.save(draft(interval: 0))),
        RepositoryDataError.invalidSchedule,
      );
      expect(
        err(await db.remindersRepository.save(draft(id: 'gone'))),
        RepositoryDataError.notFound,
      );
    });

    test('a schedule that already ended is saved finished', () async {
      final id = ok(
        await db.remindersRepository.save(
          draft(endDate: DateTime(2026, 9, 14)),
        ),
      );
      expect((await reminder(id)).status, ReminderStatus.finished);
    });

    test(
      'record inserts the occurrence and advances, undo takes it back',
      () async {
        final id = ok(await db.remindersRepository.save(draft(times: 2)));
        final before = await reminder(id);

        final first = ok(await db.remindersRepository.record(id));
        final transaction = (await db.transactionsRepository.findById(first))!;
        expect(transaction.reminderId, id);
        expect(transaction.occurredAt, DateTime(2026, 9, 15));
        expect(transaction.amount.micros, -m(40));
        expect(transaction.categoryId, groceries);
        expect(transaction.notes, 'weekly shop');
        expect(await db.transactionsRepository.labelIdsOf(first), [label]);
        expect((await reminder(id)).schedule.nextDueAt, DateTime(2026, 10, 15));
        expect((await reminder(id)).schedule.remainingOccurrences, 1);

        await db.remindersRepository.undoRecord(first, before);
        expect(await recorded(id), isEmpty);
        expect((await reminder(id)).schedule.nextDueAt, DateTime(2026, 9, 15));
        expect((await reminder(id)).schedule.remainingOccurrences, 2);

        // The last occurrence finishes it; nothing is left to record.
        ok(await db.remindersRepository.record(id));
        ok(await db.remindersRepository.record(id));
        expect((await reminder(id)).status, ReminderStatus.finished);
        expect((await reminder(id)).schedule.remainingOccurrences, 0);
        expect(
          err(await db.remindersRepository.record(id)),
          RepositoryDataError.notFound,
        );
      },
    );

    test('skip advances without a transaction', () async {
      final id = ok(await db.remindersRepository.save(draft()));
      await db.remindersRepository.skip(id);
      expect((await reminder(id)).schedule.nextDueAt, DateTime(2026, 10, 15));
      expect(await recorded(id), isEmpty);
    });

    test('history lists the recorded occurrences, newest first', () async {
      final id = ok(await db.remindersRepository.save(draft()));
      final first = ok(await db.remindersRepository.record(id));
      await db.remindersRepository.skip(id);
      final third = ok(await db.remindersRepository.record(id));
      final trashed = ok(await db.remindersRepository.record(id));
      await db.transactionsRepository.trash(trashed);
      expect((await recorded(id)).map((t) => t.id), [third, first]);
      expect((await recorded(id)).first.occurredAt, DateTime(2026, 11, 15));
    });

    test('all reminders come next due first, finished last', () async {
      final later = ok(
        await db.remindersRepository.save(draft(start: DateTime(2026, 12, 1))),
      );
      final done = ok(
        await db.remindersRepository.save(
          draft(frequency: ReminderFrequency.once),
        ),
      );
      await db.remindersRepository.skip(done);
      final paused = ok(
        await db.remindersRepository.save(draft(isPaused: true)),
      );
      final all = await db.remindersRepository.watchAll().first;
      expect(all.map((r) => r.id), [paused, later, done]);
      expect(all.map((r) => r.status), [
        ReminderStatus.paused,
        ReminderStatus.active,
        ReminderStatus.finished,
      ]);
    });

    test('delete keeps what was recorded', () async {
      final id = ok(await db.remindersRepository.save(draft()));
      final transaction = ok(await db.remindersRepository.record(id));
      await db.remindersRepository.remove(id);
      expect(await db.remindersRepository.findById(id), isNull);
      expect(
        (await db.transactionsRepository.findById(transaction))!.reminderId,
        isNull,
      );
    });

    test('automatic posting records every due occurrence, once', () async {
      final tomorrow = DateTime(2026, 9, 18);
      final auto = ok(
        await db.remindersRepository.save(
          draft(
            frequency: ReminderFrequency.weekly,
            start: DateTime(2026, 9, 1),
            autoPost: true,
          ),
        ),
      );
      final today = ok(
        await db.remindersRepository.save(
          draft(start: DateTime(2026, 9, 17, 23), autoPost: true),
        ),
      );
      final manual = ok(await db.remindersRepository.save(draft()));
      final paused = ok(
        await db.remindersRepository.save(
          draft(autoPost: true, isPaused: true),
        ),
      );
      final future = ok(
        await db.remindersRepository.save(
          draft(start: tomorrow, autoPost: true),
        ),
      );

      // September 1, 8 and 15, plus the one due tonight.
      expect(await db.remindersRepository.postDue(tomorrow), 4);
      expect((await recorded(auto)).map((t) => t.occurredAt), [
        DateTime(2026, 9, 15),
        DateTime(2026, 9, 8),
        DateTime(2026, 9, 1),
      ]);
      expect((await reminder(auto)).schedule.nextDueAt, DateTime(2026, 9, 22));
      expect(await recorded(today), hasLength(1));
      for (final id in [manual, paused, future]) {
        expect(await recorded(id), isEmpty);
      }
      expect(await db.remindersRepository.postDue(tomorrow), 0);
    });

    test(
      'repeat: today or earlier records it, the future only reminds',
      () async {
        final tomorrow = DateTime(2026, 9, 18);
        TransactionDraft on(DateTime date) => TransactionDraft(
          type: TransactionType.expense,
          occurredAt: date,
          amount: -m(12),
          assetsAccountId: bank,
          title: 'Streaming',
          labelIds: [label],
        );

        final past = ok(
          await db.remindersRepository.saveRepeating(
            on(DateTime(2026, 9, 17, 10)),
            ReminderFrequency.monthly,
            tomorrow: tomorrow,
          ),
        );
        expect(
          (await recorded(past)).single.occurredAt,
          DateTime(2026, 9, 17, 10),
        );
        expect(
          (await reminder(past)).schedule.nextDueAt,
          DateTime(2026, 10, 17, 10),
        );
        expect(
          (await reminder(past)).schedule.startDate,
          DateTime(2026, 9, 17, 10),
        );

        final future = ok(
          await db.remindersRepository.saveRepeating(
            on(tomorrow),
            ReminderFrequency.monthly,
            tomorrow: tomorrow,
          ),
        );
        expect(await recorded(future), isEmpty);
        expect((await reminder(future)).schedule.nextDueAt, tomorrow);

        // An invalid transaction leaves nothing behind.
        expect(
          err(
            await db.remindersRepository.saveRepeating(
              TransactionDraft(
                type: TransactionType.expense,
                occurredAt: tomorrow,
                amount: 0,
                assetsAccountId: bank,
              ),
              ReminderFrequency.monthly,
              tomorrow: tomorrow,
            ),
          ),
          RepositoryDataError.invalidAmount,
        );
        expect(await db.remindersRepository.watchAll().first, hasLength(2));
      },
    );
  });
}
