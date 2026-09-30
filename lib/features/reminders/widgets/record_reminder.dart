import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/result.dart';
import '../../../data/models/reminder.dart';
import '../../transactions/models/transaction_error.dart';
import '../providers/reminders_controller.dart';

/// Records the next occurrence of [reminder] and offers Undo, which deletes
/// the transaction and puts the due date back; says why when it cannot be
/// recorded.
Future<void> recordReminder(
  BuildContext context,
  WidgetRef ref,
  Reminder reminder,
) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final controller = ref.read(remindersControllerProvider.notifier);
  switch (await controller.record(reminder.id)) {
    case Ok(value: final transactionId):
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.reminderRecorded),
          action: SnackBarAction(
            label: l10n.actionUndo,
            onPressed: () => controller.undoRecord(transactionId, reminder),
          ),
        ),
      );
    case Err(:final error):
      messenger.showSnackBar(
        SnackBar(content: Text(transactionErrorMessage(error, l10n))),
      );
  }
}
