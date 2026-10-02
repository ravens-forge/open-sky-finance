import 'package:flutter/foundation.dart';

/// A folder the user granted for automatic backups.
@immutable
class BackupFolder {
  const BackupFolder({required this.ref, required this.name});

  /// What the system needs to reach it again: an Android tree URI or an iOS
  /// bookmark.
  final String ref;

  /// As the system shows it, e.g. "Open Sky Finance".
  final String name;
}
