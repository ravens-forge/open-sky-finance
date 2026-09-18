/// [name] trimmed, or `null` when it is not 1–100 characters.
String? validName(String name) {
  final trimmed = name.trim();
  return trimmed.isEmpty || trimmed.length > 100 ? null : trimmed;
}
