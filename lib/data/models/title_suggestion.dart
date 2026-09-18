import 'package:flutter/foundation.dart';

import '../enums/transaction_type.dart';

/// A transaction title to autocomplete, with the values of its latest use.
@immutable
class TitleSuggestion {
  const TitleSuggestion({
    required this.title,
    required this.type,
    required this.assetsAccountId,
    required this.toAssetsAccountId,
    required this.categoryId,
    required this.uses,
  });

  final String title;
  final TransactionType type;
  final String assetsAccountId;
  final String? toAssetsAccountId;
  final String? categoryId;
  final int uses;
}
