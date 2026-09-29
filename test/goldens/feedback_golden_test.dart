@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/features/feedback/providers/technical_info_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../pump_app.dart';
import 'golden.dart';

void main() {
  setUpAll(
    () => PackageInfo.setMockInitialValues(
      appName: 'Open Sky Finance',
      packageName: 'com.ravensforge.open_sky_finance',
      version: '1.0.0',
      buildNumber: '42',
      buildSignature: '',
    ),
  );

  appGolden(
    'report_bug',
    height: 1000,
    overrides: [osVersionProvider.overrideWith((_) async => 'Android 15')],
    act: (tester, container, l10n) async {
      container.read(routerProvider).go(Routes.reportBug);
      await settle(tester);
    },
  );

  appGolden(
    'support',
    height: 1000,
    // Pushed over Settings, as the app opens it.
    act: (tester, container, l10n) async {
      final router = container.read(routerProvider)..go(Routes.settings);
      unawaited(router.push(Routes.support));
      await settle(tester);
    },
  );
}
