@Tags(['golden'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/core/l10n.dart';
import 'package:open_sky_finance/core/widgets/info_tooltip.dart';

import '../pump_app.dart';
import 'demo_data.dart';
import 'golden.dart';

Future<void> _balanceSheet(
  WidgetTester tester,
  ProviderContainer container,
  AppLocalizations l10n,
) async {
  container.read(routerProvider).go(Routes.balanceSheet);
  await settle(tester);
}

void main() {
  appGolden('balance_sheet', height: 1180, seed: seedDemo, act: _balanceSheet);

  appGolden(
    'balance_sheet_tooltip',
    seed: seedDemo,
    act: (tester, container, l10n) async {
      await _balanceSheet(tester, container, l10n);
      await tester.tap(find.byType(InfoTooltip));
      await settle(tester);
    },
  );
}
