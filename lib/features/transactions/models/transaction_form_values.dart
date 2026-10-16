import 'package:flutter/foundation.dart';

import '../../../data/enums/reminder_frequency.dart';
import '../../../data/enums/transaction_type.dart';
import '../../../data/models/reminder_schedule.dart';
import '../../../data/models/title_suggestion.dart';

const _keep = Object();

/// What the transaction form edits besides its text fields.
@immutable
class TransactionFormValues {
  const TransactionFormValues({
    required this.type,
    required this.assetsAccountId,
    required this.toAssetsAccountId,
    required this.categoryId,
    required this.occurredAt,
    required this.labelIds,
    required this.schedule,
    required this.autoPost,
    required this.notify,
    required this.refund,
    this.repeat = ReminderFrequency.once,
    this.suggestion,
  });

  final TransactionType type;
  final String? assetsAccountId;
  final String? toAssetsAccountId;
  final String? categoryId;
  final DateTime occurredAt;
  final List<String> labelIds;

  /// Reminder form only.
  final ReminderSchedule schedule;
  final bool autoPost;
  final bool notify;

  final bool refund;

  /// "Repeat" of a new transaction; [ReminderFrequency.once] does not repeat.
  final ReminderFrequency repeat;

  /// The title suggestion last chosen, to say what it brought.
  final TitleSuggestion? suggestion;

  bool get isTransfer => type == TransactionType.transfer;

  /// Nullable fields keep their value unless one is passed, `null` included.
  TransactionFormValues copyWith({
    TransactionType? type,
    Object? assetsAccountId = _keep,
    Object? toAssetsAccountId = _keep,
    Object? categoryId = _keep,
    DateTime? occurredAt,
    List<String>? labelIds,
    ReminderSchedule? schedule,
    bool? autoPost,
    bool? notify,
    bool? refund,
    ReminderFrequency? repeat,
    Object? suggestion = _keep,
  }) => TransactionFormValues(
    type: type ?? this.type,
    assetsAccountId: identical(assetsAccountId, _keep)
        ? this.assetsAccountId
        : assetsAccountId as String?,
    toAssetsAccountId: identical(toAssetsAccountId, _keep)
        ? this.toAssetsAccountId
        : toAssetsAccountId as String?,
    categoryId: identical(categoryId, _keep)
        ? this.categoryId
        : categoryId as String?,
    occurredAt: occurredAt ?? this.occurredAt,
    labelIds: labelIds ?? this.labelIds,
    schedule: schedule ?? this.schedule,
    autoPost: autoPost ?? this.autoPost,
    notify: notify ?? this.notify,
    refund: refund ?? this.refund,
    repeat: repeat ?? this.repeat,
    suggestion: identical(suggestion, _keep)
        ? this.suggestion
        : suggestion as TitleSuggestion?,
  );

  /// A category belongs to one kind, and transfers have none; only an expense
  /// is refunded.
  TransactionFormValues withType(TransactionType type) => copyWith(
    type: type,
    categoryId: null,
    refund: type == TransactionType.expense ? refund : false,
    toAssetsAccountId: type == TransactionType.transfer
        ? toAssetsAccountId
        : null,
  );

  /// A chosen title brings the type, assets accounts and category of its
  /// latest use; its assets account only when it is still known.
  TransactionFormValues withSuggestion(
    TitleSuggestion suggestion, {
    required bool knownAssetsAccount,
  }) => copyWith(
    suggestion: suggestion,
    type: suggestion.type == TransactionType.openingBalance
        ? null
        : suggestion.type,
    assetsAccountId: knownAssetsAccount
        ? suggestion.assetsAccountId
        : assetsAccountId,
    toAssetsAccountId: suggestion.toAssetsAccountId,
    categoryId: suggestion.categoryId,
  );

  TransactionFormValues swapped() => copyWith(
    assetsAccountId: toAssetsAccountId,
    toAssetsAccountId: assetsAccountId,
  );
}
