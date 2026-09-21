import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/enums/transaction_type.dart';
import '../../../data/providers.dart';
import '../models/transaction_editor_data.dart';

part 'transaction_editor_provider.g.dart';

/// Loads the editor once; [id] `null` creates a transaction of [type].
@riverpod
Future<TransactionEditorData> transactionEditorData(
  Ref ref,
  String? id,
  TransactionType type,
) async {
  final repository = ref.watch(transactionsRepositoryProvider);
  final accounts = await ref
      .watch(assetsAccountsRepositoryProvider)
      .watchAll()
      .first;
  final transaction = id == null ? null : await repository.findById(id);
  return TransactionEditorData(
    transaction: transaction,
    labelIds: transaction == null
        ? const []
        : await repository.labelIdsOf(transaction.id),
    assetsAccounts: accounts,
    type: transaction?.type ?? type,
  );
}
