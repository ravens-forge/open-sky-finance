import 'package:flutter/foundation.dart';

import '../enums/transaction_type.dart';
import 'money.dart';
import 'reminder_schedule.dart';
import 'timestamps.dart';
import 'transfer_destination.dart';

@immutable
class Reminder {
  const Reminder({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    required this.assetsAccountId,
    required this.transfer,
    required this.categoryId,
    required this.notes,
    required this.schedule,
    required this.autoPost,
    required this.notify,
    required this.isPaused,
    required this.sortOrder,
    required this.timestamps,
  });

  final String id;

  /// Expense, income or transfer.
  final TransactionType type;
  final String title;

  /// Same sign rules as a transaction's amount.
  final Money amount;
  final String assetsAccountId;

  /// Set only on transfers.
  final TransferDestination? transfer;
  final String? categoryId;
  final String notes;
  final ReminderSchedule schedule;
  final bool autoPost;
  final bool notify;
  final bool isPaused;
  final int sortOrder;
  final Timestamps timestamps;
}
