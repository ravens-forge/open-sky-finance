import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/core/l10n.dart';
import 'package:open_sky_finance/core/links.dart';
import 'package:open_sky_finance/features/feedback/providers/technical_info_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../pump_app.dart';

const _channel = MethodChannel('plugins.flutter.io/url_launcher');

final _l10n = lookupAppLocalizations(const Locale('en'));

void main() {
  late List<String> launched;
  late String? copied;

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Open Sky Finance',
      packageName: 'com.ravensforge.open_sky_finance',
      version: '1.2.3',
      buildNumber: '4',
      buildSignature: '',
    );
    launched = [];
    copied = null;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_channel, (call) async {
      launched.add((call.arguments as Map)['url'] as String);
      return true;
    });
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(_channel, null);
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });
  });

  Future<void> open(WidgetTester tester, String route) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(800, 1600);
    addTearDown(tester.view.reset);
    final container = await pumpApp(
      tester,
      locale: 'en',
      overrides: [osVersionProvider.overrideWith((_) async => 'Android 15')],
    );
    container.read(routerProvider).go(route);
    await settle(tester);
  }

  group('Report a bug', () {
    testWidgets('previews the technical info', (tester) async {
      await open(tester, Routes.reportBug);
      for (final value in ['1.2.3 (4)', 'Android 15', 'en', '1']) {
        expect(find.text(value), findsOneWidget);
      }
    });

    testWidgets('opens the bug form with only the technical info', (
      tester,
    ) async {
      await open(tester, Routes.reportBug);
      await tester.tap(find.text(_l10n.reportBugOpen));
      await settle(tester);

      final uri = Uri.parse(launched.single);
      expect('${uri.origin}${uri.path}', '${Links.source}/issues/new');
      expect(uri.queryParameters, {
        'template': 'bug_report.yml',
        'app_version': '1.2.3 (4)',
        'platform': 'Android 15',
        'language': 'en',
        'schema_version': '1',
      });
    });

    testWidgets('the switch leaves the info out of the URL and the copy', (
      tester,
    ) async {
      await open(tester, Routes.reportBug);
      await tester.tap(find.text(_l10n.reportBugKindIdea));
      await tester.tap(find.text(_l10n.reportBugInclude));
      await settle(tester);

      await tester.tap(find.text(_l10n.reportBugCopy));
      await tester.tap(find.text(_l10n.reportBugOpen));
      await settle(tester);

      expect(launched.single, Links.featureRequest);
      expect(copied, isNull);
    });

    testWidgets('copies the same rows as plain text', (tester) async {
      await open(tester, Routes.reportBug);
      await tester.tap(find.text(_l10n.reportBugCopy));
      await settle(tester);

      expect(
        copied,
        [
          'App version: 1.2.3 (4)',
          'Platform: Android 15',
          'Language: en',
          'Database schema: 1',
        ].join('\n'),
      );
      expect(find.text(_l10n.reportBugCopied), findsOneWidget);
    });

    testWidgets('says so when no browser opens', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (_) async => false);
      await open(tester, Routes.reportBug);
      await tester.tap(find.text(_l10n.reportBugOpen));
      await settle(tester);

      expect(find.text(_l10n.errorNoBrowser), findsOneWidget);
    });
  });

  group('Support', () {
    testWidgets('Donate opens the support page on Android', (tester) async {
      await open(tester, Routes.support);
      await tester.tap(find.text(_l10n.supportDonateHint));
      await settle(tester);

      expect(launched, [Links.support]);
    });

    testWidgets('hides Donate on iOS', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        await open(tester, Routes.support);
        expect(find.text(_l10n.supportDonate), findsNothing);
        expect(find.text(_l10n.supportStar), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('Report a bug or idea opens Report a bug', (tester) async {
      await open(tester, Routes.support);
      await tester.tap(find.text(_l10n.supportReport));
      await settle(tester);

      expect(find.text(_l10n.reportBugIntro), findsOneWidget);
    });
  });
}
