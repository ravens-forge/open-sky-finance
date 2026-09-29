import 'package:flutter/foundation.dart';

@immutable
class BluecoinsTables {
  const BluecoinsTables({
    required this.userVersion,
    required this.accountTypes,
    required this.accounts,
    required this.parentCategories,
    required this.childCategories,
    required this.items,
    required this.transactions,
    required this.labels,
    required this.settings,
  });

  /// `PRAGMA user_version`: 47 in the files observed so far.
  final int userVersion;
  final List<Map<String, Object?>> accountTypes;
  final List<Map<String, Object?>> accounts;
  final List<Map<String, Object?>> parentCategories;
  final List<Map<String, Object?>> childCategories;
  final List<Map<String, Object?>> items;
  final List<Map<String, Object?>> transactions;
  final List<Map<String, Object?>> labels;
  final List<Map<String, Object?>> settings;
}
