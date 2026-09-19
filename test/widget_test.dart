import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:open_sky_finance/app/locale.dart';
import 'package:open_sky_finance/l10n/generated/app_localizations.dart';

import 'pump_app.dart';

void main() {
  test('supports English, Spanish and French', () {
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode),
      unorderedEquals(['en', 'es', 'fr']),
    );
  });

  testWidgets('app starts and shows the localized title', (tester) async {
    await pumpApp(tester);

    expect(find.text('Open Sky Finance'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  group('locale', () {
    String activeLocale(WidgetTester tester) =>
        AppLocalizations.of(tester.element(find.byType(Scaffold))).localeName;

    for (final (device, expected) in [
      (const Locale('fr', 'CA'), 'fr'),
      (const Locale('es', 'MX'), 'es'),
      (const Locale('de', 'DE'), 'en'),
    ]) {
      testWidgets('device $device resolves to $expected', (tester) async {
        tester.platformDispatcher.localesTestValue = [device];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);

        await pumpApp(tester);

        expect(activeLocale(tester), expected);
      });
    }

    testWidgets('the user choice applies immediately', (tester) async {
      tester.platformDispatcher.localesTestValue = [const Locale('es')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      final container = await pumpApp(tester);
      expect(activeLocale(tester), 'es');

      await container.read(userLocaleProvider.notifier).set(const Locale('fr'));
      await tester.pumpAndSettle();
      expect(activeLocale(tester), 'fr');

      await container.read(userLocaleProvider.notifier).set(null);
      await tester.pumpAndSettle();
      expect(activeLocale(tester), 'es');
    });
  });
}
