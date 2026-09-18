import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:open_sky_finance/app/app.dart';
import 'package:open_sky_finance/app/locale.dart';
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

        await tester.pumpWidget(const ProviderScope(child: App()));

        expect(activeLocale(tester), expected);
      });
    }

    testWidgets('the user choice applies immediately', (tester) async {
      tester.platformDispatcher.localesTestValue = [const Locale('es')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const App()),
      );
      expect(activeLocale(tester), 'es');

      container.read(userLocaleProvider.notifier).set(const Locale('fr'));
      await tester.pumpAndSettle();
      expect(activeLocale(tester), 'fr');

      container.read(userLocaleProvider.notifier).set(null);
      await tester.pumpAndSettle();
      expect(activeLocale(tester), 'es');
    });
  });
}
