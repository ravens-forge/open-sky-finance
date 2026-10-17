import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/dates/wall_clock.dart';
import '../../../core/l10n.dart';
import '../../../core/money/format_money.dart';
import '../../../core/money/parse_money.dart';
import '../../../core/result.dart';
import '../../../core/widgets/above_keyboard.dart';
import '../../../core/widgets/button_row.dart';
import '../../../core/widgets/currency_picker.dart';
import '../../../core/widgets/field_error.dart';
import '../../../core/widgets/field_row.dart';
import '../../../data/enums/assets_account_type.dart';
import '../../../data/models/assets_account_draft.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/repository_data_error.dart';
import '../models/assets_account_editor_data.dart';
import 'assets_account_delete_section.dart';
import 'assets_account_options.dart';
import 'assets_account_type_field.dart';

/// Name, type, currency, opening balance and date, options and notes; Save
/// pops. Editing adds Delete.
class AssetsAccountForm extends HookConsumerWidget {
  const AssetsAccountForm({super.key, required this.data});

  final AssetsAccountEditorData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final account = data.account;
    final name = useTextEditingController(text: account?.name);
    final notes = useTextEditingController(text: account?.notes);
    final currency = useState(data.currency);
    final balance = useTextEditingController(
      text: formatMoney(
        data.openingBalance,
        currency: data.currency,
        locale: l10n.localeName,
        symbol: false,
      ),
    );
    final type = useState(account?.type ?? AssetsAccountType.bank);
    final date = useState(data.openingBalanceDate);
    final favorite = useState(account?.isFavorite ?? false);
    final exclude = useState(account?.excludeFromNetWorth ?? false);
    final hidden = useState(account?.isHidden ?? false);
    final nameError = useState<String?>(null);
    final balanceError = useState<String?>(null);
    final saving = useState(false);
    final locked = data.transactionCount > 0;

    Future<void> save() async {
      final trimmed = name.text.trim();
      final amount = balance.text.trim().isEmpty
          ? 0
          : parseMoney(balance.text, locale: l10n.localeName);
      nameError.value = trimmed.isEmpty ? l10n.errorNameRequired : null;
      balanceError.value = amount == null ? l10n.errorInvalidAmount : null;
      if (nameError.value != null || amount == null) return;

      saving.value = true;
      final result = await ref
          .read(assetsAccountsRepositoryProvider)
          .save(
            AssetsAccountDraft(
              id: account?.id,
              name: trimmed,
              type: type.value,
              currency: currency.value,
              isHidden: hidden.value,
              isFavorite: favorite.value,
              excludeFromNetWorth: exclude.value,
              // Not editable (imported); kept while it is still a credit card.
              creditLimit: type.value == AssetsAccountType.creditCard
                  ? account?.creditLimit
                  : null,
              notes: notes.text.trim(),
              openingBalance: amount,
              openingBalanceDate: date.value,
            ),
          );
      if (!context.mounted) return;
      saving.value = false;
      switch (result) {
        case Ok():
          context.pop();
        case Err(error: RepositoryDataError.invalidName):
          nameError.value = l10n.errorNameRequired;
        case Err(:final error):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                error == RepositoryDataError.currencyLocked
                    ? l10n.errorCurrencyLocked
                    : l10n.errorSaveFailed,
              ),
            ),
          );
      }
    }

    Future<void> pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: date.value,
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
      );
      if (picked != null) date.value = startOfDay(picked);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          account == null
              ? l10n.editorNewAssetsAccount
              : l10n.editorEditAssetsAccount,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          TextField(
            controller: name,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.fieldName,
              error: nameError.value == null
                  ? null
                  : FieldError(nameError.value!),
            ),
          ),
          const SizedBox(height: 20),
          AssetsAccountTypeField(
            type: type.value,
            onChanged: (t) => type.value = t,
          ),
          const SizedBox(height: 16),
          FieldRow(
            label: l10n.fieldCurrency,
            value: currencyLabel(currency.value, l10n),
            onTap: locked
                ? null
                : () async {
                    final picked = await showCurrencyPicker(
                      context,
                      currency.value,
                    );
                    if (picked != null) currency.value = picked;
                  },
          ),
          Text(
            locked
                ? l10n.assetsAccountCurrencyLocked(data.transactionCount)
                : l10n.assetsAccountCurrencyNote,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: balance,
            onTap: () => balance.selection = TextSelection(
              baseOffset: 0,
              extentOffset: balance.text.length,
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: InputDecoration(
              labelText: l10n.fieldOpeningBalance,
              prefixText: '${currencySymbol(currency.value)} ',
              error: balanceError.value == null
                  ? null
                  : FieldError(balanceError.value!),
            ),
          ),
          FieldRow(
            label: l10n.fieldSince,
            value: DateFormat.yMMMd(l10n.localeName).format(date.value),
            onTap: pickDate,
          ),
          const SizedBox(height: 16),
          AssetsAccountOptions(
            isFavorite: favorite.value,
            excludeFromNetWorth: exclude.value,
            isHidden: hidden.value,
            onFavorite: (on) => favorite.value = on,
            onExcludeFromNetWorth: (on) => exclude.value = on,
            onHidden: (on) => hidden.value = on,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: notes,
            minLines: 2,
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.fieldNotes,
              hintText: l10n.fieldNotesHint,
            ),
          ),
          if (account != null) ...[
            const SizedBox(height: 32),
            AssetsAccountDeleteSection(
              account: account,
              transactionCount: data.transactionCount,
            ),
          ],
        ],
      ),
      bottomNavigationBar: AboveKeyboard(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: ButtonRow(
              children: [
                OutlinedButton(
                  onPressed: () => context.pop(),
                  child: Text(l10n.actionCancel),
                ),
                FilledButton(
                  onPressed: saving.value ? null : save,
                  child: Text(l10n.actionSave),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
