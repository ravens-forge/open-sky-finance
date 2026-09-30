import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/enums/transaction_type.dart';
import '../../../data/models/reminder.dart';
import '../../../data/models/transaction.dart';
import '../../../data/providers.dart';
import '../../transactions/models/transaction_editor_data.dart';

part 'reminders_providers.g.dart';

/// Every reminder, next due first and finished ones last.
@riverpod
Stream<List<Reminder>> reminders(Ref ref) =>
    ref.watch(remindersRepositoryProvider).watchAll();

/// One reminder as it changes; `null` once deleted.
@riverpod
Stream<Reminder?> reminder(Ref ref, String id) =>
    ref.watch(remindersRepositoryProvider).watchById(id);

/// The occurrences recorded from a reminder, newest first.
@riverpod
Stream<List<Transaction>> reminderHistory(Ref ref, String id) =>
    ref.watch(transactionsRepositoryProvider).watchByReminder(id);

/// Loads the reminder form once; [id] `null` creates a reminder, an expense
/// to start with: most reminders are bills.
@riverpod
Future<TransactionEditorData> reminderEditorData(Ref ref, String? id) async {
  final repository = ref.watch(remindersRepositoryProvider);
  final accounts = await ref
      .watch(assetsAccountsRepositoryProvider)
      .watchAll()
      .first;
  final reminder = id == null ? null : await repository.findById(id);
  return TransactionEditorData(
    // The form reads the template like a transaction to edit.
    transaction: reminder == null
        ? null
        : Transaction(
            id: reminder.id,
            type: reminder.type,
            occurredAt: reminder.schedule.startDate,
            title: reminder.title,
            amount: reminder.amount,
            assetsAccountId: reminder.assetsAccountId,
            transfer: reminder.transfer,
            categoryId: reminder.categoryId,
            notes: reminder.notes,
            reminderId: null,
            deletedAt: null,
            timestamps: reminder.timestamps,
          ),
    reminder: reminder,
    isReminder: true,
    labelIds: reminder == null
        ? const []
        : await repository.labelIdsOf(reminder.id),
    assetsAccounts: accounts,
    type: reminder?.type ?? TransactionType.expense,
  );
}
