@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/data/enums/transaction_type.dart';
import 'package:open_sky_finance/data/models/imported_transaction.dart';
import 'package:open_sky_finance/data/providers.dart';
import 'package:open_sky_finance/features/data_management/models/transactions_import_preview.dart';
import 'package:open_sky_finance/features/data_management/pages/transactions_import_preview_page.dart';
import 'package:open_sky_finance/features/data_management/widgets/transactions_import_flow.dart';
import 'package:open_sky_finance/services/transactions_import/models/import_file_error.dart';
import 'package:open_sky_finance/services/transactions_import/models/import_format.dart';
import 'package:open_sky_finance/services/transactions_import/models/parsed_import.dart';

import '../pump_app.dart';
import 'demo_data.dart';
import 'golden.dart';

NavigatorState _navigator(ProviderContainer container) =>
    container.read(routerProvider).routerDelegate.navigatorKey.currentState!;

/// A QIF file of one account, exported by another app: its lines name no
/// assets account.
List<ImportedTransaction> _qif() => [
  for (var day = 1; day <= 28; day++) ...[
    ImportedTransaction(
      occurredAt: DateTime(2026, 8, day),
      amount: -(day * 3 + 7) * 1000000,
      title: 'Groceries',
      category: 'Groceries',
    ),
    if (day % 7 == 0)
      ImportedTransaction(
        occurredAt: DateTime(2026, 8, day),
        amount: 150000000,
        type: TransactionType.transfer,
        toAssetsAccount: 'Old savings',
      ),
  ],
];

void main() {
  appGolden(
    'import_transactions_preview',
    seed: seedDemo,
    act: (tester, container, l10n) async {
      final accounts = await tester.runAsync(
        () => container
            .read(appDatabaseProvider)
            .customSelect('SELECT id FROM assets_accounts ORDER BY sort_order')
            .get(),
      );
      _navigator(container).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => TransactionsImportPreviewPage(
            preview: TransactionsImportPreview(
              fileName: 'checking-august.qif',
              size: 48231,
              parsed: ParsedImport(
                format: ImportFormat.qif,
                transactions: _qif(),
                unreadable: 2,
              ),
              newAssetsAccounts: 1,
              defaultAssetsAccountId: accounts!.first.read<String>('id'),
            ),
          ),
        ),
      );
      await settle(tester);
    },
  );

  appGolden(
    'import_transactions_error',
    seed: seedDemo,
    act: (tester, container, l10n) async {
      unawaited(container.read(routerProvider).push(Routes.settings));
      await settle(tester);
      unawaited(
        showImportErrorDialog(
          _navigator(container).context,
          ImportFileError.missingColumns,
        ),
      );
      await settle(tester);
    },
  );
}
