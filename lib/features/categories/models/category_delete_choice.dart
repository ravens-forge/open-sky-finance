import 'package:flutter/foundation.dart';

/// The user's answer to the delete confirmation of a category or group.
@immutable
class CategoryDeleteChoice {
  const CategoryDeleteChoice(this.reassignTo);

  /// Where its transactions and reminders go; `null` leaves them
  /// uncategorized.
  final String? reassignTo;
}
