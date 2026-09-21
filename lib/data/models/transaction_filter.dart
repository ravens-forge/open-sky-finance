import 'package:flutter/foundation.dart';

import '../enums/transaction_type.dart';

/// What the transactions list shows: a text search over titles and notes plus
/// optional assets account, category, label and type filters. An empty filter
/// matches every live transaction of the period.
@immutable
class TransactionFilter {
  const TransactionFilter({
    this.query = '',
    this.type,
    this.assetsAccountId,
    this.categoryId,
    this.labelId,
  });

  final String query;
  final TransactionType? type;

  /// Either side of a transfer.
  final String? assetsAccountId;
  final String? categoryId;
  final String? labelId;

  /// Filters other than the search, for the "Filters (2)" button.
  int get count => [type, assetsAccountId, categoryId, labelId].nonNulls.length;

  TransactionFilter _with({
    String? query,
    TransactionType? type,
    String? assetsAccountId,
    String? categoryId,
    String? labelId,
  }) => TransactionFilter(
    query: query ?? this.query,
    type: type,
    assetsAccountId: assetsAccountId,
    categoryId: categoryId,
    labelId: labelId,
  );

  TransactionFilter withQuery(String query) => _with(
    query: query,
    type: type,
    assetsAccountId: assetsAccountId,
    categoryId: categoryId,
    labelId: labelId,
  );

  /// `null` clears the filter. Transfers have no category, so choosing that
  /// type drops it.
  TransactionFilter withType(TransactionType? type) => _with(
    type: type,
    assetsAccountId: assetsAccountId,
    categoryId: type == TransactionType.transfer ? null : categoryId,
    labelId: labelId,
  );

  TransactionFilter withAssetsAccount(String? id) => _with(
    type: type,
    assetsAccountId: id,
    categoryId: categoryId,
    labelId: labelId,
  );

  TransactionFilter withCategory(String? id) => _with(
    type: type,
    assetsAccountId: assetsAccountId,
    categoryId: id,
    labelId: labelId,
  );

  TransactionFilter withLabel(String? id) => _with(
    type: type,
    assetsAccountId: assetsAccountId,
    categoryId: categoryId,
    labelId: id,
  );

  /// Keeps the search, drops every filter.
  TransactionFilter cleared() => TransactionFilter(query: query);

  @override
  bool operator ==(Object other) =>
      other is TransactionFilter &&
      other.query == query &&
      other.type == type &&
      other.assetsAccountId == assetsAccountId &&
      other.categoryId == categoryId &&
      other.labelId == labelId;

  @override
  int get hashCode =>
      Object.hash(query, type, assetsAccountId, categoryId, labelId);
}
