import 'package:flutter/foundation.dart';

import '../../../data/enums/transaction_type.dart';
import '../../../data/models/assets_account.dart';
import '../../../data/models/transaction.dart';

@immutable
class TransactionEditorData {
  const TransactionEditorData({
    required this.transaction,
    required this.labelIds,
    required this.assetsAccounts,
    required this.type,
  });

  final Transaction? transaction;
  final List<String> labelIds;

  /// Every assets account, hidden ones included: an edited transaction can
  /// point at one.
  final List<AssetsAccount> assetsAccounts;

  /// The type the editor opens with.
  final TransactionType type;
}
