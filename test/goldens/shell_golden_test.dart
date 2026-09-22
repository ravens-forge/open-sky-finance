@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/core/widgets/launch_screen.dart';
import 'package:open_sky_finance/core/widgets/page_placeholder.dart';

import '../pump_app.dart';
import 'demo_data.dart';
import 'golden.dart';

void main() {
  appGolden(
    'drawer',
    seed: seedDemo,
    act: (tester, container, l10n) async {
      await tester.tap(find.byIcon(Icons.menu));
      await settle(tester);
    },
  );

  for (final (i, step) in [
    'welcome',
    'basics',
    'first_assets_account',
  ].indexed) {
    appGolden(
      'onboarding_$step',
      onboarded: false,
      act: (tester, container, l10n) async {
        for (var next = 0; next < i; next++) {
          await tester.tap(find.text(l10n.actionNext));
          await settle(tester);
        }
      },
    );
  }

  widgetGolden(
    'loading_app_launch',
    (context) => const LaunchScreen(delay: Duration.zero),
    settle: false,
  );

  widgetGolden(
    'loading_page_content',
    (context) => const PagePlaceholder(label: ''),
  );
}
