enum BluecoinsSkipReason {
  /// Transactions deleted in Bluecoins.
  deleted,

  /// Reminder and recurring templates.
  reminder,

  /// A transfer leg without its other side.
  orphanTransfer,

  /// A transaction type or state the importer does not know.
  unknownType,

  /// A transaction in another currency than its assets account.
  otherCurrency,

  /// A transaction on an assets account that was not imported.
  missingAssetsAccount,

  /// Budgets whose period cannot be confirmed as monthly.
  budget,

  /// Entries with a missing name, currency, date or amount, or a category
  /// in a group that was not imported.
  invalid,
}
