/// Comma-separated values (RFC 4180): quoted fields may hold the delimiter,
/// quotes (doubled) and line breaks.
abstract final class CsvTable {
  /// The byte order mark: spreadsheets read the file as UTF-8 with it.
  static final bom = String.fromCharCode(0xFEFF);

  /// Rows of fields. The delimiter is the one of `,` and `;` (what
  /// spreadsheets in many European languages save) found more often in the
  /// first line.
  static List<List<String>> parse(String text) {
    final body = text.startsWith(bom) ? text.substring(1) : text;
    final firstLine = body.split('\n').first;
    final delimiter =
        ';'.allMatches(firstLine).length > ','.allMatches(firstLine).length
        ? ';'
        : ',';
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var quoted = false;
    for (var i = 0; i < body.length; i++) {
      final c = body[i];
      if (quoted) {
        if (c != '"') {
          field.write(c);
        } else if (i + 1 < body.length && body[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else if (c == '"') {
        quoted = true;
      } else if (c == delimiter) {
        row.add(field.toString());
        field.clear();
      } else if (c == '\n' || c == '\r') {
        if (c == '\r' && i + 1 < body.length && body[i + 1] == '\n') i++;
        row.add(field.toString());
        field.clear();
        rows.add(row);
        row = <String>[];
      } else {
        field.write(c);
      }
    }
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    // Blank lines are not rows.
    return [
      for (final r in rows)
        if (r.any((f) => f.trim().isNotEmpty)) r,
    ];
  }

  /// CSV with CRLF line ends and a byte order mark, so spreadsheets read
  /// accents right.
  static String encode(List<List<String>> rows) {
    String quote(String f) => f.contains(RegExp(r'[,;"\r\n]')) || f.trim() != f
        ? '"${f.replaceAll('"', '""')}"'
        : f;
    return '$bom${rows.map((r) => r.map(quote).join(',')).join('\r\n')}\r\n';
  }
}
