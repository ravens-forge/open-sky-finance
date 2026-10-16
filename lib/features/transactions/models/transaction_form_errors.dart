import 'package:flutter/foundation.dart';

/// The messages the transaction form shows under its fields after Save.
@immutable
class TransactionFormErrors {
  const TransactionFormErrors({
    this.amount,
    this.title,
    this.assetsAccount,
    this.destination,
    this.received,
  });

  final String? amount;
  final String? title;
  final String? assetsAccount;
  final String? destination;
  final String? received;

  bool get any =>
      amount != null ||
      title != null ||
      assetsAccount != null ||
      destination != null ||
      received != null;
}
