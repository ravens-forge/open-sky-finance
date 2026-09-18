import 'package:flutter/foundation.dart';

@immutable
class Label {
  const Label({required this.id, required this.name});

  final String id;

  /// Unique ignoring case.
  final String name;
}
