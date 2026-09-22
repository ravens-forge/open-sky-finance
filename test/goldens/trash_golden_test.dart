@Tags(['golden'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/core/l10n.dart';

import '../pump_app.dart';
import 'demo_data.dart';
import 'golden.dart';

Future<void> _trash(
  WidgetTester tester,
  ProviderContainer container,
  AppLocalizations l10n,
) async {
  container.read(routerProvider).go(Routes.trash);
  await settle(tester);
}

void main() {
  appGolden('trash', seed: seedDemo, act: _trash);

  appGolden('trash_empty', act: _trash);

  appGolden(
    'delete_permanently_confirm',
    seed: seedDemo,
    act: (tester, container, l10n) async {
      await _trash(tester, container, l10n);
      await tester.tap(find.byTooltip(l10n.trashDeletePermanently).first);
      await settle(tester);
    },
  );
}
