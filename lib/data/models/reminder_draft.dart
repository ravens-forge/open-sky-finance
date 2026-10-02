import 'package:flutter/foundation.dart';

import 'reminder_schedule.dart';
import 'transaction_draft.dart';

/// What the reminder editor saves. [id] `null` creates a reminder.
@immutable
class ReminderDraft {
  const ReminderDraft({
    this.id,
    required this.template,
    required this.schedule,
    this.autoPost = false,
    this.notify = false,
    this.isPaused = false,
  });

  final String? id;

  /// The transaction each occurrence records. Its `id`, `occurredAt` and
  /// `reminderId` are not used: the schedule gives the dates.
  final TransactionDraft template;
  final ReminderSchedule schedule;
  final bool autoPost;

  /// A local notification on each due date.
  final bool notify;
  final bool isPaused;
}
