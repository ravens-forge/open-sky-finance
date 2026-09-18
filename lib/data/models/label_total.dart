import 'package:flutter/foundation.dart';

import 'label.dart';

/// A label with its transactions in a period.
@immutable
class LabelTotal {
  const LabelTotal({
    required this.label,
    required this.count,
    required this.total,
  });

  final Label label;

  /// Transactions, transfers included.
  final int count;

  /// Signed micro-units by currency; transfers add nothing.
  final Map<String, int> total;
}
