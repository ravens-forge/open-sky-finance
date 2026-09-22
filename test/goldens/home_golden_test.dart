@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/core/widgets/home_section_header.dart';

import '../pump_app.dart';
import 'demo_data.dart';
import 'golden.dart';

void main() {
  appGolden('home', height: 1500, showHome: true, seed: seedDemo);

  appGolden('home_empty', height: 1100, showHome: true);

  // A section lifted over its dashed drop slot.
  appGolden(
    'home_dragging',
    height: 1500,
    showHome: true,
    seed: seedDemo,
    act: (tester, container, l10n) async {
      final handle = find.descendant(
        of: find.widgetWithText(HomeSectionHeader, l10n.homeSectionNetWorth),
        matching: find.byIcon(Icons.drag_indicator),
      );
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -320));
      await tester.pump();
      // Released after the capture, when the test tears down.
      addTearDown(gesture.up);
    },
  );

  appGolden(
    'arrange_home',
    showHome: true,
    seed: seedDemo,
    act: (tester, container, l10n) async {
      unawaited(container.read(routerProvider).push(Routes.homeSections));
      await settle(tester);
    },
  );

  appGolden(
    'favorite_accounts_sheet',
    showHome: true,
    seed: seedDemo,
    act: (tester, container, l10n) async {
      await tester.tap(find.text(l10n.actionEdit));
      await settle(tester);
    },
  );
}
