import 'package:flutter/foundation.dart';

/// Where a transfer goes. Only transfers have one.
@immutable
class TransferDestination {
  const TransferDestination({
    required this.assetsAccountId,
    this.amountReceived,
    this.exchangeRate,
  });

  final String assetsAccountId;

  /// Micro-units in the destination currency, between currencies only;
  /// otherwise the amount sent is received.
  final int? amountReceived;

  /// Decimal string (`amountReceived / amount`), between currencies only.
  /// Informative: never used for balances.
  final String? exchangeRate;
}
