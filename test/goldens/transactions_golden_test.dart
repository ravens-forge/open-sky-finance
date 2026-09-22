@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/core/l10n.dart';
import 'package:open_sky_finance/data/enums/transaction_type.dart';

import '../pump_app.dart';
import 'demo_data.dart';
import 'golden.dart';

Future<void> _open(
  WidgetTester tester,
  ProviderContainer container,
  String path,
) async {
  container.read(routerProvider).go(path);
  await settle(tester);
}

/// The new expense editor with [field]'s picker open.
Future<void> Function(WidgetTester, ProviderContainer, AppLocalizations)
_picker(String Function(AppLocalizations l10n) field) =>
    (tester, container, l10n) async {
      await _open(tester, container, Routes.newTransaction());
      final target = find.text(field(l10n)).last;
      await tester.ensureVisible(target);
      await tester.tap(target);
      await settle(tester);
    };

void main() {
  appGolden(
    'transactions',
    height: 1200,
    seed: seedDemo,
    act: (tester, container, l10n) =>
        _open(tester, container, Routes.transactions),
  );

  appGolden(
    'transactions_empty',
    act: (tester, container, l10n) =>
        _open(tester, container, Routes.transactions),
  );

  for (final type in TransactionType.values.where(
    (t) => t != TransactionType.openingBalance,
  )) {
    appGolden(
      'new_transaction_${type.name}',
      height: 1000,
      seed: seedDemo,
      act: (tester, container, l10n) =>
          _open(tester, container, Routes.newTransaction(type)),
    );
  }

  appGolden(
    'edit_transaction',
    height: 1000,
    seed: seedDemo,
    act: (tester, container, l10n) => _open(
      tester,
      container,
      Routes.transaction(demo['tx:La Plaza Restaurant']!),
    ),
  );

  appGolden(
    'transaction_form_errors',
    height: 1000,
    seed: seedDemo,
    act: (tester, container, l10n) async {
      await _open(tester, container, Routes.newTransaction());
      await tester.tap(find.widgetWithText(FilledButton, l10n.actionSave));
      await settle(tester);
    },
  );

  appGolden(
    'assets_account_picker_sheet',
    seed: seedDemo,
    act: _picker((l10n) => l10n.fieldAssetsAccount),
  );
  appGolden(
    'category_picker_sheet',
    seed: seedDemo,
    act: _picker((l10n) => l10n.fieldCategory),
  );
  appGolden(
    'labels_picker_sheet',
    seed: seedDemo,
    act: _picker((l10n) => l10n.actionAdd),
  );
}
