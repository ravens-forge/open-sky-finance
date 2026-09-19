import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/dates/wall_clock.dart';
import '../../../core/l10n.dart';
import '../../../core/money/format_money.dart';
import '../../../core/money/parse_money.dart';
import '../../../core/result.dart';
import '../../../core/widgets/currency_picker.dart';
import '../../../core/widgets/field_error.dart';
import '../../../core/widgets/field_row.dart';
import '../../../data/enums/assets_account_type.dart';
import '../../../data/models/assets_account_draft.dart';
import '../../../data/repositories/repository_data_error.dart';
import '../models/assets_account_editor_data.dart';
import '../providers/assets_accounts_controller.dart';
import 'assets_account_delete_section.dart';
import 'assets_account_options.dart';
import 'assets_account_type_field.dart';

/// Name, type, currency, opening balance and date, options and notes; Save
/// pops. Editing adds Delete.
class AssetsAccountForm extends ConsumerStatefulWidget {
  const AssetsAccountForm({super.key, required this.data});

  final AssetsAccountEditorData data;

  @override
  ConsumerState<AssetsAccountForm> createState() => _AssetsAccountFormState();
}

class _AssetsAccountFormState extends ConsumerState<AssetsAccountForm> {
  late final _account = widget.data.account;
  late final _name = TextEditingController(text: _account?.name);
  late final _notes = TextEditingController(text: _account?.notes);
  final _balance = TextEditingController();
  late var _type = _account?.type ?? AssetsAccountType.bank;
  late var _currency = widget.data.currency;
  late var _date = widget.data.openingBalanceDate;
  late var _favorite = _account?.isFavorite ?? false;
  late var _exclude = _account?.excludeFromNetWorth ?? false;
  late var _hidden = _account?.isHidden ?? false;
  String? _nameError;
  String? _balanceError;
  var _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_balance.text.isEmpty) {
      _balance.text = formatMoney(
        widget.data.openingBalance,
        currency: _currency,
        locale: context.l10n.localeName,
        symbol: false,
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final name = _name.text.trim();
    final balance = _balance.text.trim().isEmpty
        ? 0
        : parseMoney(_balance.text, locale: l10n.localeName);
    setState(() {
      _nameError = name.isEmpty ? l10n.errorNameRequired : null;
      _balanceError = balance == null ? l10n.errorInvalidAmount : null;
    });
    if (_nameError != null || balance == null) return;

    setState(() => _saving = true);
    final result = await ref
        .read(assetsAccountsControllerProvider.notifier)
        .save(
          AssetsAccountDraft(
            id: _account?.id,
            name: name,
            type: _type,
            currency: _currency,
            isHidden: _hidden,
            isFavorite: _favorite,
            excludeFromNetWorth: _exclude,
            // Not editable (imported); kept while it is still a credit card.
            creditLimit: _type == AssetsAccountType.creditCard
                ? _account?.creditLimit
                : null,
            notes: _notes.text.trim(),
            openingBalance: balance,
            openingBalanceDate: _date,
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok():
        context.pop();
      case Err(error: RepositoryDataError.invalidName):
        setState(() => _nameError = l10n.errorNameRequired);
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = startOfDay(picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locked = widget.data.transactionCount > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _account == null
              ? l10n.editorNewAssetsAccount
              : l10n.editorEditAssetsAccount,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.fieldName,
              error: _nameError == null ? null : FieldError(_nameError!),
            ),
          ),
          const SizedBox(height: 20),
          AssetsAccountTypeField(
            type: _type,
            onChanged: (t) => setState(() => _type = t),
          ),
          const SizedBox(height: 16),
          FieldRow(
            label: l10n.fieldCurrency,
            value: currencyLabel(_currency, l10n),
            onTap: locked
                ? null
                : () async {
                    final picked = await showCurrencyPicker(context, _currency);
                    if (picked != null) setState(() => _currency = picked);
                  },
          ),
          Text(
            locked
                ? l10n.assetsAccountCurrencyLocked(widget.data.transactionCount)
                : l10n.assetsAccountCurrencyNote,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _balance,
            onTap: () => _balance.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _balance.text.length,
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: InputDecoration(
              labelText: l10n.fieldOpeningBalance,
              prefixText: '${currencySymbol(_currency)} ',
              error: _balanceError == null ? null : FieldError(_balanceError!),
            ),
          ),
          FieldRow(
            label: l10n.fieldSince,
            value: DateFormat.yMMMd(l10n.localeName).format(_date),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          AssetsAccountOptions(
            isFavorite: _favorite,
            excludeFromNetWorth: _exclude,
            isHidden: _hidden,
            onFavorite: (on) => setState(() => _favorite = on),
            onExcludeFromNetWorth: (on) => setState(() => _exclude = on),
            onHidden: (on) => setState(() => _hidden = on),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notes,
            minLines: 2,
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.fieldNotes,
              hintText: l10n.fieldNotesHint,
            ),
          ),
          if (_account != null) ...[
            const SizedBox(height: 32),
            AssetsAccountDeleteSection(
              account: _account,
              transactionCount: widget.data.transactionCount,
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: Text(l10n.actionCancel),
                ),
              ),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(l10n.actionSave),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
