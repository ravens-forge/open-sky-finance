import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/now.dart';
import '../../../core/result.dart';
import '../../../data/enums/reminder_frequency.dart';
import '../../../data/models/title_suggestion.dart';
import '../../../data/models/transaction_draft.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/repository_data_error.dart';
import '../../../data/repositories/transactions_repository.dart';

part 'transactions_controller.g.dart';

/// Writes of the Transactions screens. The lists update through their
/// streams.
@Riverpod(keepAlive: true)
class TransactionsController extends _$TransactionsController {
  @override
  FutureOr<void> build() {}

  TransactionsRepository get _repository =>
      ref.read(transactionsRepositoryProvider);

  Future<Result<String, RepositoryDataError>> save(TransactionDraft draft) =>
      _repository.save(draft);

  /// "Repeat": creates a reminder of [draft] every [frequency]. Dated today
  /// or earlier, the transaction is saved too and the reminder starts at the
  /// next occurrence.
  Future<Result<String, RepositoryDataError>> saveRepeating(
    TransactionDraft draft,
    ReminderFrequency frequency,
  ) => ref
      .read(remindersRepositoryProvider)
      .saveRepeating(draft, frequency, tomorrow: ref.read(tomorrowProvider));

  /// Moves it to the Trash; [restore] is the Undo of the snack bar.
  Future<void> trash(String id) => _repository.trash(id);

  Future<void> restore(String id) => _repository.restore(id);

  Future<List<TitleSuggestion>> titleSuggestions(String prefix) =>
      _repository.titleSuggestions(prefix);

  /// Creates a label from the labels picker. Returns its id.
  Future<Result<String, RepositoryDataError>> createLabel(String name) =>
      ref.read(labelsRepositoryProvider).save(name: name);
}
