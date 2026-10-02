import 'package:flutter/foundation.dart';

import 'restore_choice.dart';

/// What the import preview closed with: import (into [assetsAccountId] for
/// the rows that name none) or pick another file.
@immutable
class TransactionsImportChoice {
  const TransactionsImportChoice(this.choice, {this.assetsAccountId});

  final RestoreChoice choice;
  final String? assetsAccountId;
}
