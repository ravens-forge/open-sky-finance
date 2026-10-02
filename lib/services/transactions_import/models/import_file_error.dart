/// Why a file can't be imported. Codes only: the UI words them.
enum ImportFileError {
  /// Over the size limit, rejected before reading it.
  tooLarge,

  /// Not text, or neither CSV nor QIF.
  notReadable,

  /// A CSV file without a date or an amount column.
  missingColumns,

  /// Read, but without a single transaction.
  empty,

  /// Reading the file or writing the data failed; nothing changed.
  failed,
}
