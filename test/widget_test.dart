import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:open_sky_finance/app/app.dart';
import 'package:open_sky_finance/l10n/generated/app_localizations.dart';

void main() {
  test('supports English, Spanish and French', () {
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode),
      unorderedEquals(['en', 'es', 'fr']),
    );
  });

  testWidgets('app starts and shows the localized title', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));

    expect(find.text('Open Sky Finance'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
