import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables/reminders_table.dart';
import '../models/reminder.dart';

part 'reminders_repository.g.dart';

@DriftAccessor(tables: [RemindersTable])
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
}
