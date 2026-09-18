import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

Iterable<String> _keys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@'));

/// How [message] uses [placeholder]: `{name}` → '', `{name, plural, …}` → 'plural'.
Set<String> _uses(String message, String placeholder) =>
    RegExp('\\{${RegExp.escape(placeholder)}\\s*(?:,\\s*(\\w+))?')
        .allMatches(message)
        .map((m) => m[1] ?? '')
        .toSet();

void main() {
  final en = _arb('en');

  for (final locale in ['es', 'fr']) {
    final arb = _arb(locale);

    test('$locale has the same keys as en', () {
      expect(_keys(arb).toSet(), _keys(en).toSet());
    });

    test('$locale uses the same placeholders as en', () {
      for (final key in _keys(en)) {
        final placeholders =
            ((en['@$key'] as Map?)?['placeholders'] as Map?)?.keys ?? [];
        for (final p in placeholders.cast<String>()) {
          expect(
            _uses(arb[key] as String, p),
            _uses(en[key] as String, p),
            reason: '$key: {$p}',
          );
        }
      }
    });
  }
}
