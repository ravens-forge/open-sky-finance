import 'package:flutter/foundation.dart';

import '../../../data/enums/transaction_type.dart';
import '../../../services/bluecoins/models/loaded_bluecoins.dart';
import '../../assets_accounts/models/assets_account_with_balance.dart';

@immutable
class BluecoinsPreview {
  const BluecoinsPreview({
    required this.file,
    required this.balances,
    required this.transactions,
    required this.transfers,
    required this.first,
    required this.last,
  });

  /// Balances before [before] (midnight tonight), to compare with what
  /// Bluecoins shows today.
  factory BluecoinsPreview.of(
    LoadedBluecoins file, {
    required DateTime before,
  }) {
    final snapshot = file.import.snapshot;
    final balances = snapshot.balances(before);
    final dates = [for (final t in snapshot.transactions) t.occurredAt]..sort();
    return BluecoinsPreview(
      file: file,
      balances: [
        for (final a in snapshot.assetsAccounts)
          AssetsAccountWithBalance(a.toDomain(), balances[a.id]!),
      ],
      transactions: snapshot.transactions
          .where(
            (t) =>
                t.type == TransactionType.income ||
                t.type == TransactionType.expense,
          )
          .length,
      transfers: snapshot.transactions
          .where((t) => t.type == TransactionType.transfer)
          .length,
      first: dates.firstOrNull,
      last: dates.lastOrNull,
    );
  }

  final LoadedBluecoins file;

  /// Every assets account to import, in the file's order.
  final List<AssetsAccountWithBalance> balances;

  /// Income and expenses.
  final int transactions;
  final int transfers;

  /// Dates of the oldest and newest transactions; `null` when there is none.
  final DateTime? first;
  final DateTime? last;
}
