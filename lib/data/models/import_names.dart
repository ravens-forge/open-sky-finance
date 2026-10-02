import 'package:flutter/foundation.dart';

/// Names an import gives what it creates, in the user's language.
@immutable
class ImportNames {
  const ImportNames({required this.categoryGroup});

  /// The group of a category the file names without one.
  final String categoryGroup;
}
