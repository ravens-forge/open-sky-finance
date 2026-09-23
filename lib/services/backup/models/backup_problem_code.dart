enum BackupProblemCode {
  /// A required field is not there.
  missing,

  /// A string where a number goes, and the like.
  wrongType,

  /// The right type, but not an allowed value: an unknown enum, a bad date,
  /// a name too long…
  invalidValue,

  /// Two entries of one collection share an id.
  duplicateId,

  /// Two labels share a name.
  duplicateName,

  /// An id that points at nothing in the file.
  unknownReference,

  /// Breaks a rule between fields, e.g. a transfer into its own assets
  /// account.
  brokenRule,
}
