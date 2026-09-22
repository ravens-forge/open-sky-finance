import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/main_currency.dart';
import '../../../app/now.dart';
import '../../../data/providers.dart';
import '../models/assets_account_editor_data.dart';

part 'assets_account_editor_provider.g.dart';

/// Loads the editor once; [id] `null` creates an assets account.
@riverpod
Future<AssetsAccountEditorData> assetsAccountEditorData(
  Ref ref,
  String? id,
) async {
  final repository = ref.watch(assetsAccountsRepositoryProvider);
  final today = ref.read(todayProvider);
  final account = id == null ? null : await repository.findById(id);
  if (account == null) {
    return AssetsAccountEditorData(
      account: null,
      currency: await ref.watch(mainCurrencyProvider.future),
      openingBalance: 0,
      openingBalanceDate: today,
      transactionCount: 0,
    );
  }
  final opening = await repository.openingBalanceOf(account.id);
  return AssetsAccountEditorData(
    account: account,
    currency: account.currency,
    openingBalance: opening?.amount.micros ?? 0,
    openingBalanceDate: opening?.occurredAt ?? today,
    transactionCount: await repository.countTransactions(account.id),
  );
}
