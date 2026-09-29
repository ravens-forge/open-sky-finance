/// Why a Bluecoins backup cannot be imported. Codes only: the UI words them.
sealed class BluecoinsImportError {
  const BluecoinsImportError();
}

/// Over the size limit, rejected before copying it.
final class BluecoinsFileTooLarge extends BluecoinsImportError {
  const BluecoinsFileTooLarge();
}

/// A ZIP archive: compressed backups are not supported yet.
final class BluecoinsCompressed extends BluecoinsImportError {
  const BluecoinsCompressed();
}

/// Not an SQLite database, or one without the Bluecoins tables.
final class BluecoinsNotABackup extends BluecoinsImportError {
  const BluecoinsNotABackup();
}

/// A Bluecoins backup in a format this version cannot read.
final class BluecoinsMissingColumns extends BluecoinsImportError {
  const BluecoinsMissingColumns(this.columns);

  /// `TABLE.column`: names from the format, never data from the file.
  final List<String> columns;
}

/// SQLite reports the file as damaged, or cannot open it.
final class BluecoinsDamaged extends BluecoinsImportError {
  const BluecoinsDamaged();
}

/// Reading the file, the safety backup or the write failed. The data was not
/// changed.
final class BluecoinsImportFailed extends BluecoinsImportError {
  const BluecoinsImportFailed();
}
