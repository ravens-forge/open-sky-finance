enum BluecoinsNote {
  /// Assets accounts of an unknown type, imported as other assets or other
  /// liabilities.
  unknownAssetsAccountType,

  /// Income or expenses whose category was not found, imported without one.
  uncategorized,

  /// Parts of split transactions, imported as separate transactions.
  splitTransaction,
}
