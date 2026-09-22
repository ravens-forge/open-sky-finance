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

Future<void> _netIncome(
  WidgetTester tester,
  ProviderContainer container,
  AppLocalizations l10n,
) async {
  container.read(routerProvider).go(Routes.netIncome);
  await settle(tester);
}

void main() {
  appGolden('net_income', height: 1420, seed: seedDemo, act: _netIncome);

  appGolden(
    'net_income_tooltip',
    seed: seedDemo,
    act: (tester, container, l10n) async {
      await _netIncome(tester, container, l10n);
      await tester.tap(find.byType(InfoTooltip).first);
      await settle(tester);
    },
  );

  appGolden(
    'net_income_quarter',
    height: 1420,
    seed: seedDemo,
    act: (tester, container, l10n) async {
      await _netIncome(tester, container, l10n);
      await tester.tap(find.text(l10n.netIncomePeriodQuarter));
      await settle(tester);
    },
  );
}
