/// Why a repository refused a write. An error code, never UI text.
enum RepositoryDataError {
  notFound,

  /// Empty or longer than 100 characters after trimming.
  invalidName,
  duplicateName,

  /// Not 3 upper-case letters (ISO 4217).
  invalidCurrency,

  /// The assets account already has transactions.
  currencyLocked,
  creditLimitNotAllowed,
  invalidAmount,

  /// Opening balances are written through the assets account.
  invalidType,
  transferToSameAssetsAccount,

  /// Transfer between currencies without the amount received.
  toAmountRequired,

  /// Destination fields on a non-transfer, or an amount received between
  /// assets accounts of the same currency.
  toAmountNotAllowed,
  categoryNotAllowed,
  categoryKindMismatch,

  /// A group's kind is fixed once it has categories or transactions.
  kindLocked,
  groupHasCategories,
}
