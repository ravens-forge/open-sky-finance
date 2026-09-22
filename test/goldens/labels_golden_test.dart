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

Future<void> _labels(
  WidgetTester tester,
  ProviderContainer container,
  AppLocalizations l10n,
) async {
  container.read(routerProvider).go(Routes.labels);
  await settle(tester);
}

/// The Labels page with the options of "vacation" open, then [option].
Future<void> Function(WidgetTester, ProviderContainer, AppLocalizations)
_options([String Function(AppLocalizations l10n)? option]) =>
    (tester, container, l10n) async {
      await _labels(tester, container, l10n);
      await tester.longPress(find.text('vacation'));
      await settle(tester);
      if (option != null) {
        await tester.tap(find.text(option(l10n)).last);
        await settle(tester);
      }
    };

void main() {
  appGolden('labels', seed: seedDemo, act: _labels);

  appGolden('labels_empty', act: _labels);

  appGolden(
    'labels_tooltip',
    seed: seedDemo,
    act: (tester, container, l10n) async {
      await _labels(tester, container, l10n);
      await tester.tap(find.byType(InfoTooltip));
      await settle(tester);
    },
  );

  appGolden('labels_options_sheet', seed: seedDemo, act: _options());

  appGolden(
    'new_label_dialog',
    seed: seedDemo,
    act: (tester, container, l10n) async {
      await _labels(tester, container, l10n);
      await tester.tap(find.text(l10n.labelsNew));
      await settle(tester);
    },
  );

  appGolden(
    'rename_label_dialog',
    seed: seedDemo,
    act: _options((l10n) => l10n.actionRename),
  );

  appGolden(
    'delete_label_confirm',
    seed: seedDemo,
    act: _options((l10n) => l10n.actionDelete),
  );
}
