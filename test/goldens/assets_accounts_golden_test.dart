@Tags(['golden'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/core/l10n.dart';
import 'package:open_sky_finance/core/widgets/destructive_button.dart';
import 'package:open_sky_finance/core/widgets/info_tooltip.dart';

import '../pump_app.dart';
import 'demo_data.dart';
import 'golden.dart';

/// Opens the page at the path [route] builds from the demo ids.
Future<void> Function(WidgetTester, ProviderContainer, AppLocalizations) _open(
  String Function() route,
) => (tester, container, l10n) async {
  container.read(routerProvider).go(route());
  await settle(tester);
};

void main() {
  appGolden(
    'assets_accounts',
    height: 1100,
    seed: seedDemo,
    act: _open(() => Routes.assetsAccounts),
  );

  appGolden(
    'assets_account_detail',
    height: 1100,
    seed: seedDemo,
    act: _open(() => Routes.assetsAccount(demo['Visa']!)),
  );

  appGolden(
    'assets_account_detail_tooltip',
    seed: seedDemo,
    act: (tester, container, l10n) async {
      await _open(() => Routes.assetsAccount(demo['Visa']!))(
        tester,
        container,
        l10n,
      );
      await tester.tap(find.byType(InfoTooltip).first);
      await settle(tester);
    },
  );

  appGolden(
    'new_assets_account',
    height: 1000,
    seed: seedDemo,
    act: _open(() => Routes.newAssetsAccount),
  );

  appGolden(
    'edit_assets_account',
    height: 1200,
    seed: seedDemo,
    act: _open(() => Routes.editAssetsAccount(demo['Visa']!)),
  );

  appGolden(
    'delete_assets_account_confirm',
    seed: seedDemo,
    act: (tester, container, l10n) async {
      await _open(() => Routes.editAssetsAccount(demo['Visa']!))(
        tester,
        container,
        l10n,
      );
      await scrollTo(tester, find.byType(DestructiveButton));
      await tester.tap(find.byType(DestructiveButton));
      await settle(tester);
    },
  );
}
