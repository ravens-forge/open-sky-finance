import 'package:flutter/foundation.dart';

import '../enums/assets_account_type.dart';
import 'timestamps.dart';

@immutable
class AssetsAccount {
  const AssetsAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.isHidden,
    required this.isFavorite,
    required this.excludeFromNetWorth,
    required this.creditLimit,
    required this.sortOrder,
    required this.notes,
    required this.timestamps,
  });

  final String id;
  final String name;
  final AssetsAccountType type;

  /// ISO 4217. Every transaction of this assets account is in this currency.
  final String currency;

  /// Hidden from pickers and totals.
  final bool isHidden;
  final bool isFavorite;
  final bool excludeFromNetWorth;

  /// Micro-units, credit cards only.
  final int? creditLimit;
  final int sortOrder;
  final String notes;

  final Timestamps timestamps;
}
