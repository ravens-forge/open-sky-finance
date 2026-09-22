import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/theme.dart';
import 'package:open_sky_finance/core/l10n.dart';
import 'package:open_sky_finance/data/database/app_database.dart';
import 'package:open_sky_finance/data/repositories/setting_keys.dart';

import '../pump_app.dart';

/// "Now" in every golden: Thursday, September 17, 2026.
final goldenNow = DateTime(2026, 9, 17, 10, 30);

/// Each golden is taken in English (light and dark), Spanish and French.
enum GoldenVariant {
  light('en', ThemeMode.light),
  dark('en', ThemeMode.dark),
  es('es', ThemeMode.light),
  fr('fr', ThemeMode.light);

  const GoldenVariant(this.locale, this.themeMode);

  final String locale;
  final ThemeMode themeMode;
}

/// A phone screen (390 wide) of [height], with real shadows, the clock at
/// [goldenNow], and `images/<name>/<variant>.png` as the golden file.
Future<void> _capture(
  WidgetTester tester,
  String name,
  GoldenVariant variant,
  double height,
  Future<void> Function() pump,
) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = Size(390, height);
  addTearDown(tester.view.reset);
  // The test binding draws shadows as solid outlines unless told not to, and
  // checks the flag is back on before the tear-downs run.
  debugDisableShadows = false;
  try {
    await pump();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('images/$name/${variant.name}.png'),
    );
  } finally {
    debugDisableShadows = true;
  }
}

/// Golden of the whole app in each [GoldenVariant]: [seed] writes the data,
/// then [act] opens the screen, sheet or dialog to capture, finding what it
/// taps by the variant's own strings.
void appGolden(
  String name, {
  double height = 844,
  bool onboarded = true,
  bool showHome = false,
  List<Override> overrides = const [],
  Future<void> Function(AppDatabase db)? seed,
  Future<void> Function(
    WidgetTester tester,
    ProviderContainer container,
    AppLocalizations l10n,
  )?
  act,
}) {
  for (final variant in GoldenVariant.values) {
    testWidgets('$name (${variant.name})', (tester) async {
      await _capture(tester, name, variant, height, () async {
        final container = await pumpApp(
          tester,
          onboarded: onboarded,
          showHome: showHome,
          locale: variant.locale,
          now: goldenNow,
          overrides: overrides,
          seed: (db) async {
            await db.settingsRepository.set(
              SettingKeys.themeMode,
              variant.themeMode.name,
            );
            await seed?.call(db);
          },
        );
        await act?.call(
          tester,
          container,
          lookupAppLocalizations(Locale(variant.locale)),
        );
      });
    });
  }
}

/// Golden of a widget on its own, on a page of the app theme, in each
/// [GoldenVariant]; without [settle], captured half a second in.
void widgetGolden(
  String name,
  WidgetBuilder builder, {
  double height = 844,
  bool settle = true,
}) {
  for (final variant in GoldenVariant.values) {
    testWidgets('$name (${variant.name})', (tester) async {
      await _capture(tester, name, variant, height, () async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale(variant.locale),
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: variant.themeMode,
            home: Scaffold(
              body: SafeArea(child: Builder(builder: builder)),
            ),
          ),
        );
        // Endless animations (an indeterminate progress line) never settle.
        settle
            ? await tester.pumpAndSettle()
            : await tester.pump(const Duration(milliseconds: 500));
      });
    });
  }
}

/// Scrolls the page's list until [finder], built lazily, is on screen.
Future<void> scrollTo(WidgetTester tester, Finder finder) => tester
    .scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
