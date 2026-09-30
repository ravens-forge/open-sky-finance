import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/now.dart';
import '../../../core/result.dart';
import '../../../data/models/reminder.dart';
import '../../../data/models/reminder_draft.dart';
import '../../../data/models/transaction_draft.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/reminders_repository.dart';
import '../../../data/repositories/repository_data_error.dart';

part 'reminders_controller.g.dart';

/// Writes of the Reminders screens. The lists update through their streams.
@Riverpod(keepAlive: true)
class RemindersController extends _$RemindersController {
  @override
  FutureOr<void> build() {}

  RemindersRepository get _repository => ref.read(remindersRepositoryProvider);

  Future<Result<String, RepositoryDataError>> save(ReminderDraft draft) =>
      _repository.save(draft);

  /// Saves what the page of a reminder changes and keeps the rest of
  /// [reminder], its labels included.
  Future<Result<String, RepositoryDataError>> saveChanges(
    Reminder reminder, {
    required bool isPaused,
    required bool autoPost,
    required String assetsAccountId,
    required String? categoryId,
  }) async => _repository.save(
    ReminderDraft(
      id: reminder.id,
      template: TransactionDraft(
        type: reminder.type,
        occurredAt: reminder.schedule.startDate,
        amount: reminder.amount.micros,
        assetsAccountId: assetsAccountId,
        toAssetsAccountId: reminder.transfer?.assetsAccountId,
        toAmount: reminder.transfer?.amountReceived,
        categoryId: categoryId,
        title: reminder.title,
        notes: reminder.notes,
        labelIds: await _repository.labelIdsOf(reminder.id),
      ),
      schedule: reminder.schedule,
      autoPost: autoPost,
      isPaused: isPaused,
    ),
  );

  Future<void> remove(String id) => _repository.remove(id);

  /// Records the next occurrence. Returns the id of the transaction, which
  /// [undoRecord] takes back.
  Future<Result<String, RepositoryDataError>> record(String id) =>
      _repository.record(id);

  Future<void> undoRecord(String transactionId, Reminder before) =>
      _repository.undoRecord(transactionId, before);

  Future<void> skip(String id) => _repository.skip(id);

  /// Records what the automatic reminders have due up to today. Returns how
  /// many occurrences were recorded.
  Future<int> postDue() => _repository.postDue(ref.read(tomorrowProvider));
}
