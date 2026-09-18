// Latin-1 and Latin Extended-A letters folded to their base letters.
const _folds = {
  'àáâãäåāăą': 'a',
  'æ': 'ae',
  'çćĉċč': 'c',
  'ďđð': 'd',
  'èéêëēĕėęě': 'e',
  'ĝğġģ': 'g',
  'ĥħ': 'h',
  'ìíîïĩīĭįı': 'i',
  'ĳ': 'ij',
  'ĵ': 'j',
  'ķĸ': 'k',
  'ĺļľŀł': 'l',
  'ñńņňŉŋ': 'n',
  'òóôõöøōŏő': 'o',
  'œ': 'oe',
  'ŕŗř': 'r',
  'śŝşšſ': 's',
  'ß': 'ss',
  'ţťŧ': 't',
  'þ': 'th',
  'ùúûüũūŭůűų': 'u',
  'ŵ': 'w',
  'ýÿŷ': 'y',
  'źżž': 'z',
};

final _table = {
  for (final MapEntry(:key, :value) in _folds.entries)
    for (final rune in key.runes) rune: value,
};

/// A case- and accent-insensitive key for sorting names: `Électricité` sorts with
/// `electricite`, `Ñandú` with `nandu`.
String sortKey(String name) {
  final key = StringBuffer();
  for (final rune in name.toLowerCase().runes) {
    // Combining accents, from decomposed input.
    if (rune >= 0x0300 && rune <= 0x036F) continue;
    key.write(_table[rune] ?? String.fromCharCode(rune));
  }
  return key.toString();
}
