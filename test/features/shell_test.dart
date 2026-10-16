import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';

import '../pump_app.dart';

String location(GoRouter router) => router.state.uri.toString();

void main() {
  testWidgets('first launch goes to onboarding; Skip goes Home', (
    tester,
  ) async {
    final router = (await pumpApp(
      tester,
      onboarded: false,
    )).read(routerProvider);
    expect(location(router), Routes.onboarding);

    await tester.tap(find.text('Skip'));
    await settle(tester);
    expect(location(router), Routes.home);
    expect(find.text('Open Sky Finance'), findsOneWidget);
  });

  testWidgets('tabs, swipe and branch stay in sync', (tester) async {
    final router = (await pumpApp(tester)).read(routerProvider);
    expect(location(router), Routes.home);

    await tester.tap(find.text('Transactions'));
    await settle(tester);
    expect(location(router), Routes.transactions);

    await tester.fling(find.byType(TabBarView), const Offset(-400, 0), 1000);
    await settle(tester);
    expect(location(router), Routes.reminders);

    router.go(Routes.labels);
    await settle(tester);
    final tabs = tester.widget<TabBar>(find.byType(TabBar)).controller!;
    expect(tabs.index, 6);
  });

  testWidgets(
    'FAB only shows on Transactions, and opens the editor above the shell',
    (tester) async {
      final router = (await pumpApp(tester)).read(routerProvider);
      expect(find.text('Add'), findsNothing);

      await tester.tap(find.text('Transactions'));
      await settle(tester);
      await tester.tap(find.text('Add'));
      await settle(tester);
      expect(location(router), Routes.newTransaction());
      expect(find.text('New transaction'), findsOneWidget);
      expect(find.byType(TabBar), findsNothing);

      await tester.tap(find.byTooltip('Close'));
      await settle(tester);
      expect(location(router), Routes.transactions);
    },
  );

  testWidgets('back on a tab goes Home, back on Home leaves', (tester) async {
    final router = (await pumpApp(tester)).read(routerProvider);

    router.go(Routes.budgets);
    await settle(tester);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await settle(tester);
    expect(location(router), Routes.home);

    expect(await tester.binding.handlePopRoute(), isFalse);
  });

  testWidgets('back closes a pushed page before going Home', (tester) async {
    final router = (await pumpApp(tester)).read(routerProvider);

    await tester.tap(find.text('Transactions'));
    await settle(tester);
    await tester.tap(find.byTooltip('Calendar'));
    await settle(tester);
    expect(location(router), Routes.calendar);

    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(location(router), Routes.transactions);

    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(location(router), Routes.home);
  });

  testWidgets('drawer opens other pages', (tester) async {
    final router = (await pumpApp(tester)).read(routerProvider);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await settle(tester);
    await tester.tap(find.text('Categories'));
    await settle(tester);
    expect(location(router), Routes.categories);
  });

  testWidgets('unknown IDs and paths show not found', (tester) async {
    final router = (await pumpApp(tester)).read(routerProvider);

    for (final path in [
      Routes.transaction('missing'),
      Routes.assetsAccount('missing'),
      Routes.category('missing'),
      '/nowhere',
    ]) {
      router.go(path);
      await settle(tester);
      expect(find.text('Nothing here'), findsOneWidget, reason: path);
    }

    await tester.tap(find.text('Go to Home'));
    await settle(tester);
    expect(location(router), Routes.home);
  });
}
