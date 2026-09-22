@Tags(['golden'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/core/l10n.dart';
import 'package:open_sky_finance/core/labels.dart';
import 'package:open_sky_finance/core/widgets/destructive_button.dart';
import 'package:open_sky_finance/data/enums/category_kind.dart';

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

/// Opens the editor at [route] and taps its Delete button.
Future<void> Function(WidgetTester, ProviderContainer, AppLocalizations)
_delete(String Function() route) => (tester, container, l10n) async {
  await _open(route)(tester, container, l10n);
  await scrollTo(tester, find.byType(DestructiveButton));
  await tester.tap(find.byType(DestructiveButton));
  await settle(tester);
};

void main() {
  // The expense groups.
  appGolden(
    'categories',
    height: 1300,
    seed: seedDemo,
    act: (tester, container, l10n) async {
      await _open(() => Routes.categories)(tester, container, l10n);
      await tester.tap(
        find.textContaining(CategoryKind.expense.label(l10n)).first,
      );
      await settle(tester);
    },
  );

  appGolden(
    'new_category',
    height: 1000,
    seed: seedDemo,
    act: _open(() => Routes.newCategory(CategoryKind.expense)),
  );

  appGolden(
    'edit_category',
    height: 1100,
    seed: seedDemo,
    act: _open(() => Routes.category(demo['Groceries']!)),
  );

  appGolden(
    'new_category_group',
    seed: seedDemo,
    act: _open(() => Routes.newCategoryGroup(CategoryKind.expense)),
  );

  appGolden(
    'edit_category_group',
    seed: seedDemo,
    act: _open(() => Routes.categoryGroup(demo['Food']!)),
  );

  appGolden(
    'delete_category_confirm',
    seed: seedDemo,
    act: _delete(() => Routes.category(demo['Groceries']!)),
  );

  // An empty group.
  appGolden(
    'delete_category_group_confirm',
    seed: seedDemo,
    act: _delete(() => Routes.categoryGroup(demo['Other']!)),
  );
}
