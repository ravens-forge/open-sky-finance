import 'package:flutter/foundation.dart';

@immutable
class Timestamps {
  const Timestamps({required this.createdAt, required this.updatedAt});

  /// Both set to [now], for new records.
  const Timestamps.at(DateTime now) : this(createdAt: now, updatedAt: now);

  final DateTime createdAt;
  final DateTime updatedAt;
}
