import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/info_note.dart';
import '../../../data/enums/transaction_type.dart';
import '../../../services/transactions_import/models/import_format.dart';
import '../../assets_accounts/providers/assets_accounts_providers.dart';
import '../../assets_accounts/widgets/assets_account_picker_sheet.dart';
import '../../settings/widgets/settings_row.dart';
import '../models/restore_choice.dart';
import '../models/transactions_import_choice.dart';
import '../models/transactions_import_preview.dart';
import '../widgets/backup_file_row.dart';
import '../widgets/file_size_label.dart';
import '../widgets/restore_preview_actions.dart';
import '../widgets/restore_preview_heading.dart';
import '../widgets/restore_preview_row.dart';

/// What a CSV or QIF file adds, and the assets account its rows without one
/// go to. Pops a [TransactionsImportChoice].
class TransactionsImportPreviewPage extends ConsumerStatefulWidget {
  const TransactionsImportPreviewPage({super.key, required this.preview});

  final TransactionsImportPreview preview;

  @override
  ConsumerState<TransactionsImportPreviewPage> createState() =>
      _TransactionsImportPreviewPageState();
}

class _TransactionsImportPreviewPageState
    extends ConsumerState<TransactionsImportPreviewPage> {
  late var _assetsAccountId = widget.preview.defaultAssetsAccountId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final count = NumberFormat.decimalPattern(l10n.localeName).format;
    final day = DateFormat.yMMMd(l10n.localeName).format;
    final p = widget.preview;
    final rows = p.parsed.transactions;
    final transfers = rows
        .where((t) => t.type == TransactionType.transfer)
        .length;
    final needsAccount = p.parsed.needsAssetsAccount;
    final accounts = ref.watch(assetsAccountsProvider).value ?? const [];
    final account = accounts.where((a) => a.id == _assetsAccountId).firstOrNull;
    void pop([TransactionsImportChoice? choice]) =>
        Navigator.pop(context, choice);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.importTransactions)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          BackupFileRow(
            name: p.fileName,
            subtitle: l10n.importFileReady(
              p.parsed.format == ImportFormat.qif ? 'QIF' : 'CSV',
              fileSizeLabel(l10n, p.size),
            ),
            onChange: () =>
                pop(const TransactionsImportChoice(RestoreChoice.change)),
          ),
          RestorePreviewHeading(l10n.importWhatWillBeAdded),
          RestorePreviewRow(l10n.pageTransactions, count(rows.length)),
          if (transfers > 0)
            RestorePreviewRow(l10n.bluecoinsTransfers, count(transfers)),
          RestorePreviewRow(
            l10n.bluecoinsDates,
            l10n.bluecoinsDateRange(day(p.first), day(p.last)),
          ),
          RestorePreviewRow(
            l10n.importNewAssetsAccounts,
            count(p.newAssetsAccounts),
          ),
          if (p.parsed.unreadable > 0)
            RestorePreviewRow(
              l10n.importUnreadable,
              count(p.parsed.unreadable),
            ),
          if (needsAccount) ...[
            RestorePreviewHeading(
              l10n.importIntoAssetsAccount,
              caption: l10n.importIntoAssetsAccountHint,
            ),
            SettingsRow(
              icon: Icons.account_balance_outlined,
              title: account?.name ?? l10n.importChooseAssetsAccount,
              subtitle: account?.currency,
              action: l10n.actionChange,
              onTap: () async {
                final picked = await showAssetsAccountPickerSheet(
                  context,
                  selectedId: _assetsAccountId,
                );
                if (picked != null) setState(() => _assetsAccountId = picked);
              },
            ),
          ],
          const SizedBox(height: 24),
          InfoNote(l10n.importNote, icon: Icons.info_outline),
        ],
      ),
      bottomNavigationBar: RestorePreviewActions(
        onCancel: pop,
        onRestore: needsAccount && account == null
            ? null
            : () => pop(
                TransactionsImportChoice(
                  RestoreChoice.restore,
                  assetsAccountId: _assetsAccountId,
                ),
              ),
        label: l10n.importAction,
      ),
    );
  }
}
