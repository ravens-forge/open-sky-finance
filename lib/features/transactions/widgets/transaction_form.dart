import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/money/format_money.dart';
import '../../../core/money/parse_money.dart';
import '../../../core/result.dart';
import '../../../core/widgets/field_error.dart';
import '../../../core/widgets/editor_row.dart';
import '../../../core/widgets/ledger_dialog.dart';
import '../../../core/widgets/type_selector.dart';
import '../../../data/enums/category_kind.dart';
import '../../../data/enums/transaction_type.dart';
import '../../../data/models/assets_account.dart';
import '../../../data/models/category.dart';
import '../../../data/models/category_group.dart';
import '../../../data/models/title_suggestion.dart';
import '../../../data/models/transaction_draft.dart';
import '../../assets_accounts/models/assets_account_with_balance.dart';
import '../../assets_accounts/providers/assets_accounts_providers.dart';
import '../../assets_accounts/widgets/assets_account_picker_sheet.dart';
import '../../categories/providers/categories_providers.dart';
import '../../categories/widgets/category_picker_sheet.dart';
import '../models/transaction_editor_data.dart';
import '../models/transaction_error.dart';
import '../providers/transactions_controller.dart';
import 'transaction_amount_field.dart';
import 'transaction_date_time_fields.dart';
import 'transaction_form_actions.dart';
import 'transaction_labels_field.dart';
import 'transaction_refund_row.dart';
import 'transaction_title_field.dart';
import 'transaction_transfer_fields.dart';

/// Type, amount, title, category or transfer destination, assets account,
/// date and time, labels and notes. Amounts are typed positive: the type and
/// the refund toggle give them their sign.
class TransactionForm extends ConsumerStatefulWidget {
  const TransactionForm({super.key, required this.data});

  final TransactionEditorData data;

  @override
  ConsumerState<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<TransactionForm> {
  late final _transaction = widget.data.transaction;
  late var _type = widget.data.type;
  late final _title = TextEditingController(text: _transaction?.title);
  late final _notes = TextEditingController(text: _transaction?.notes);
  final _amount = TextEditingController();
  final _received = TextEditingController();
  final _rate = TextEditingController();
  late String? _assetsAccountId =
      _transaction?.assetsAccountId ??
      widget.data.assetsAccounts.where((a) => !a.isHidden).firstOrNull?.id;
  late var _toAssetsAccountId = _transaction?.transfer?.assetsAccountId;
  late var _categoryId = _transaction?.categoryId;
  late var _occurredAt = _transaction?.occurredAt ?? DateTime.now();
  late var _labelIds = [...widget.data.labelIds];
  late var _refund =
      _transaction?.type == TransactionType.expense &&
      _transaction!.amount.micros > 0;
  String? _amountError;
  String? _accountError;
  String? _destinationError;
  String? _receivedError;
  var _saving = false;

  /// The title suggestion last chosen, to say what it brought.
  TitleSuggestion? _suggestion;

  /// Assets accounts with their balances as they change: one created from the
  /// picker shows up at once.
  var _live = <String, AssetsAccountWithBalance>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final t = _transaction;
    if (t != null && _amount.text.isEmpty) {
      _amount.text = _money(t.amount.micros.abs(), t.amount.currency);
      if (t.transfer?.amountReceived case final received?) {
        _received.text = _money(received, _currencyOf(_toAssetsAccountId));
        _syncRate();
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _amount.dispose();
    _received.dispose();
    _rate.dispose();
    super.dispose();
  }

  String _money(int micros, String currency) => formatMoney(
    micros,
    currency: currency,
    locale: context.l10n.localeName,
    symbol: false,
  );

  int? _parse(TextEditingController field) =>
      parseMoney(field.text, locale: context.l10n.localeName);

  AssetsAccount? _accountOf(String? id) =>
      _live[id]?.account ??
      widget.data.assetsAccounts.where((a) => a.id == id).firstOrNull;

  String _currencyOf(String? id) => _accountOf(id)?.currency ?? '';

  bool get _isTransfer => _type == TransactionType.transfer;

  /// A transfer whose destination holds another currency needs the amount
  /// received.
  bool get _crossCurrency =>
      _isTransfer &&
      _toAssetsAccountId != null &&
      _currencyOf(_toAssetsAccountId) != _currencyOf(_assetsAccountId);

  /// `a * b / c` without overflowing on large amounts.
  int _mulDiv(int a, int b, int c) =>
      (BigInt.from(a) * BigInt.from(b) ~/ BigInt.from(c)).toInt();

  /// The rate is what the amount received is worth per unit sent, so each of
  /// the two fields fills the other.
  void _syncRate() {
    final amount = _parse(_amount);
    final received = _parse(_received);
    if (amount == null || amount <= 0 || received == null || received <= 0) {
      return;
    }
    _rate.text = _money(
      _mulDiv(received, microsPerUnit, amount),
      _currencyOf(_toAssetsAccountId),
    );
  }

  void _syncReceived() {
    final amount = _parse(_amount);
    final rate = _parse(_rate);
    if (amount == null || amount <= 0 || rate == null || rate <= 0) return;
    _received.text = _money(
      _mulDiv(amount, rate, microsPerUnit),
      _currencyOf(_toAssetsAccountId),
    );
  }

  void _setType(TransactionType type) => setState(() {
    _type = type;
    // A category belongs to one kind, and transfers have none.
    _categoryId = null;
    if (type == TransactionType.transfer) {
      _refund = false;
    } else {
      _toAssetsAccountId = null;
      _received.clear();
      _rate.clear();
    }
    if (type == TransactionType.income) _refund = false;
  });

  /// A chosen title brings the type, assets accounts and category of its
  /// latest use.
  void _applySuggestion(TitleSuggestion suggestion) => setState(() {
    _suggestion = suggestion;
    if (suggestion.type != TransactionType.openingBalance) {
      _type = suggestion.type;
    }
    if (_accountOf(suggestion.assetsAccountId) != null) {
      _assetsAccountId = suggestion.assetsAccountId;
    }
    _toAssetsAccountId = suggestion.toAssetsAccountId;
    _categoryId = suggestion.categoryId;
  });

  Future<void> _pickCategory() async {
    final picked = await showCategoryPickerSheet(
      context,
      kind: _type == TransactionType.income
          ? CategoryKind.income
          : CategoryKind.expense,
      selectedId: _categoryId,
    );
    if (picked != null) setState(() => _categoryId = picked);
  }

  Future<void> _pickAssetsAccount({required bool destination}) async {
    final picked = await showAssetsAccountPickerSheet(
      context,
      selectedId: destination ? _toAssetsAccountId : _assetsAccountId,
      excludeId: destination ? _assetsAccountId : _toAssetsAccountId,
    );
    if (picked == null) return;
    setState(() {
      if (destination) {
        _toAssetsAccountId = picked;
      } else {
        _assetsAccountId = picked;
      }
    });
  }

  /// Typing the rate fills the amount received.
  Future<void> _editRate() async {
    final l10n = context.l10n;
    var typed = _rate.text;
    final rate = await showLedgerDialog<String>(
      context: context,
      title: l10n.fieldRate,
      body: l10n.transactionRate(
        _currencyOf(_assetsAccountId),
        '?',
        _currencyOf(_toAssetsAccountId),
      ),
      extra: TextFormField(
        initialValue: typed,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (value) => typed = value,
      ),
      actions: [
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel),
          ),
        ),
        Builder(
          builder: (context) => FilledButton(
            onPressed: () => Navigator.pop(context, typed),
            child: Text(l10n.actionSave),
          ),
        ),
      ],
    );
    if (rate == null) return;
    setState(() {
      _rate.text = rate;
      _syncReceived();
    });
  }

  void _swap() => setState(() {
    final from = _assetsAccountId;
    _assetsAccountId = _toAssetsAccountId;
    _toAssetsAccountId = from;
    _received.clear();
    _rate.clear();
  });

  Future<void> _save({required bool again}) async {
    final l10n = context.l10n;
    final amount = _parse(_amount);
    final received = _crossCurrency ? _parse(_received) : null;
    setState(() {
      _amountError = switch (amount) {
        null when _amount.text.trim().isEmpty => l10n.errorAmountRequired,
        null => l10n.errorInvalidAmount,
        <= 0 => l10n.errorAmountRequired,
        _ => null,
      };
      _accountError = _assetsAccountId == null
          ? l10n.errorAssetsAccountRequired
          : null;
      _destinationError = switch (_toAssetsAccountId) {
        _ when !_isTransfer => null,
        null => l10n.errorDestinationRequired,
        final id when id == _assetsAccountId => l10n.errorDestinationSame,
        _ => null,
      };
      _receivedError = _crossCurrency && (received == null || received <= 0)
          ? l10n.errorAmountReceivedRequired
          : null;
    });
    if (_amountError != null ||
        _accountError != null ||
        _destinationError != null ||
        _receivedError != null) {
      return;
    }

    setState(() => _saving = true);
    final result = await ref
        .read(transactionsControllerProvider.notifier)
        .save(
          TransactionDraft(
            id: _transaction?.id,
            type: _type,
            // Wall clock: to the minute, no seconds and no time zone.
            occurredAt: DateTime(
              _occurredAt.year,
              _occurredAt.month,
              _occurredAt.day,
              _occurredAt.hour,
              _occurredAt.minute,
            ),
            amount: _type == TransactionType.expense && !_refund
                ? -amount!
                : amount!,
            assetsAccountId: _assetsAccountId!,
            toAssetsAccountId: _isTransfer ? _toAssetsAccountId : null,
            toAmount: received,
            categoryId: _isTransfer ? null : _categoryId,
            title: _title.text.trim(),
            notes: _notes.text.trim(),
            labelIds: _labelIds,
            reminderId: _transaction?.reminderId,
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok() when again:
        _startAnother();
      case Ok():
        context.pop();
      case Err(:final error):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(transactionErrorMessage(error, l10n))),
        );
    }
  }

  /// "Save and add another": keeps the type, assets accounts, category and
  /// date, clears what belongs to the saved transaction.
  void _startAnother() {
    _title.clear();
    _notes.clear();
    _amount.clear();
    _received.clear();
    _rate.clear();
    setState(() {
      _labelIds = [];
      _refund = false;
      _suggestion = null;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.transactionSaved)));
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final id = _transaction!.id;
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(transactionsControllerProvider.notifier);
    await controller.trash(id);
    if (!mounted) return;
    context.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.transactionsMovedToTrash),
        action: SnackBarAction(
          label: l10n.actionUndo,
          onPressed: () => controller.restore(id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final finance = FinanceColors.of(context);
    _live = {
      for (final a
          in ref.watch(assetsAccountsWithBalanceProvider).value ??
              const <AssetsAccountWithBalance>[])
        a.account.id: a,
    };
    final categories = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    final groups = {
      for (final g
          in ref.watch(categoryGroupsProvider).value ?? const <CategoryGroup>[])
        g.id: g.name,
    };
    final category = categories[_categoryId];
    final currency = _currencyOf(_assetsAccountId);

    /// "Wallet · EUR · €186.50".
    String accountValue(String? id) {
      final account = _accountOf(id);
      if (account == null) return l10n.actionChoose;
      return l10n.assetsAccountSummary(
        account.name,
        account.currency,
        formatMoney(
          _live[id]?.balance ?? 0,
          currency: account.currency,
          locale: l10n.localeName,
        ),
      );
    }

    final (String sign, Color color) = switch (_type) {
      TransactionType.transfer => ('⇄', finance.transfer),
      TransactionType.income => ('+', finance.income),
      _ when _refund => ('+', finance.income),
      _ => ('−', finance.expense),
    };
    final suggested = switch (_suggestion) {
      null => null,
      final s when s.type == TransactionType.transfer => l10n.transferFromTo(
        _accountOf(s.assetsAccountId)?.name ?? '',
        _accountOf(s.toAssetsAccountId)?.name ?? '',
      ),
      final s => l10n.transactionSubtitle(
        categories[s.categoryId]?.name ?? l10n.categoryNone,
        _accountOf(s.assetsAccountId)?.name ?? '',
      ),
    };
    final title = TransactionTitleField(
      controller: _title,
      onSuggestion: _applySuggestion,
      suggested: suggested,
    );
    final t = _transaction;
    String stamp(DateTime utc) =>
        DateFormat.yMMMd(l10n.localeName).add_jm().format(utc.toLocal());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t == null ? l10n.editorNewTransaction : l10n.editorEditTransaction,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: theme.colorScheme.outline),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
        children: [
          TypeSelector<TransactionType>(
            options: [
              (TransactionType.income, '+ ${l10n.transactionTypeIncome}'),
              (TransactionType.expense, '− ${l10n.transactionTypeExpense}'),
              (TransactionType.transfer, '⇄ ${l10n.transactionTypeTransfer}'),
            ],
            selected: _type,
            onChanged: _setType,
          ),
          TransactionAmountField(
            controller: _amount,
            label: l10n.fieldAmount,
            currency: currency,
            color: color,
            sign: sign,
            autofocus: t == null,
            error: _amountError,
          ),
          if (_type == TransactionType.expense)
            TransactionRefundRow(
              value: _refund,
              onChanged: (on) => setState(() => _refund = on),
            ),
          if (_isTransfer) ...[
            TransactionTransferFields(
              fromValue: accountValue(_assetsAccountId),
              toValue: accountValue(_toAssetsAccountId),
              onFrom: () => _pickAssetsAccount(destination: false),
              onTo: () => _pickAssetsAccount(destination: true),
              onSwap: _swap,
              fromCurrency: currency,
              toCurrency: _toAssetsAccountId == null
                  ? null
                  : _currencyOf(_toAssetsAccountId),
              received: _received,
              onReceived: (_) => setState(_syncRate),
              rate: _rate.text,
              onEditRate: _editRate,
              destinationError: _destinationError,
              receivedError: _receivedError,
            ),
            title,
          ] else ...[
            title,
            EditorRow(
              icon: Icons.grid_view,
              label: l10n.fieldCategory,
              onTap: _pickCategory,
              child: Text(
                category == null
                    ? l10n.actionChoose
                    : l10n.categoryInGroup(
                        groups[category.groupId] ?? '',
                        category.name,
                      ),
              ),
            ),
            EditorRow(
              icon: Icons.credit_card,
              label: l10n.fieldAssetsAccount,
              helper: l10n.transactionAmountCurrencyNote,
              onTap: () => _pickAssetsAccount(destination: false),
              child: Text(accountValue(_assetsAccountId)),
            ),
          ],
          if (_accountError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: FieldError(_accountError!),
            ),
          TransactionDateTimeFields(
            dateTime: _occurredAt,
            onChanged: (value) => setState(() => _occurredAt = value),
          ),
          TransactionLabelsField(
            labelIds: _labelIds,
            onChanged: (ids) => setState(() => _labelIds = ids),
          ),
          EditorRow(
            icon: Icons.article_outlined,
            label: l10n.fieldNotes,
            child: TextField(
              controller: _notes,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l10n.fieldNotesHint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (t != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                l10n.transactionTimestamps(
                  stamp(t.timestamps.createdAt),
                  stamp(t.timestamps.updatedAt),
                ),
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
      bottomNavigationBar: TransactionFormActions(
        saving: _saving,
        onSave: () => _save(again: false),
        onSaveAndAddAnother: t == null ? () => _save(again: true) : null,
        onDelete: t == null ? null : _delete,
      ),
    );
  }
}
