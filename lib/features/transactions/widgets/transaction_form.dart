import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/now.dart';
import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/money/format_money.dart';
import '../../../core/money/parse_money.dart';
import '../../../core/result.dart';
import '../../../core/widgets/above_keyboard.dart';
import '../../../core/widgets/editor_row.dart';
import '../../../core/widgets/field_error.dart';
import '../../../core/widgets/ledger_dialog.dart';
import '../../../core/widgets/type_selector.dart';
import '../../../data/enums/category_kind.dart';
import '../../../data/enums/reminder_frequency.dart';
import '../../../data/enums/transaction_type.dart';
import '../../../data/models/assets_account.dart';
import '../../../data/models/category.dart';
import '../../../data/models/category_group.dart';
import '../../../data/models/reminder_draft.dart';
import '../../../data/models/reminder_schedule.dart';
import '../../../data/models/transaction_draft.dart';
import '../../../data/providers.dart';
import '../../assets_accounts/models/assets_account_with_balance.dart';
import '../../assets_accounts/providers/assets_accounts_providers.dart';
import '../../assets_accounts/widgets/assets_account_picker_sheet.dart';
import '../../categories/providers/categories_providers.dart';
import '../../categories/widgets/category_picker_sheet.dart';
import '../models/transaction_editor_data.dart';
import '../models/transaction_error.dart';
import '../models/transaction_form_errors.dart';
import '../models/transaction_form_values.dart';
import 'transaction_amount_field.dart';
import 'transaction_date_time_fields.dart';
import 'transaction_form_actions.dart';
import 'transaction_labels_field.dart';
import 'transaction_refund_row.dart';
import 'transaction_reminder_fields.dart';
import 'transaction_repeat_field.dart';
import 'transaction_title_field.dart';
import 'transaction_transfer_fields.dart';

/// Type, amount, title, category or transfer destination, assets account,
/// date and time, labels and notes. Amounts are typed positive: the type and
/// the refund toggle give them their sign. "Repeat" turns a new transaction
/// into a reminder, and the reminder form is this one with a schedule in
/// place of the date and time.
class TransactionForm extends HookConsumerWidget {
  const TransactionForm({super.key, required this.data, this.date});

  final TransactionEditorData data;

  /// The day a new transaction starts on, at the current time; today when
  /// `null`.
  final DateTime? date;

  /// [now] moved to [date], keeping the time.
  DateTime _onDate(DateTime now) => switch (date) {
    final date? => DateTime(
      date.year,
      date.month,
      date.day,
      now.hour,
      now.minute,
    ),
    null => now,
  };

  /// `a * b / c` without overflowing on large amounts.
  static int _mulDiv(int a, int b, int c) =>
      (BigInt.from(a) * BigInt.from(b) ~/ BigInt.from(c)).toInt();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final finance = FinanceColors.of(context);
    final t = data.transaction;
    final reminder = data.reminder;
    final isReminder = data.isReminder;

    final state = useState(
      useMemoized(
        () => TransactionFormValues(
          type: data.type,
          assetsAccountId:
              t?.assetsAccountId ??
              data.assetsAccounts.where((a) => !a.isHidden).firstOrNull?.id,
          toAssetsAccountId: t?.transfer?.assetsAccountId,
          categoryId: t?.categoryId,
          occurredAt: t?.occurredAt ?? _onDate(ref.read(nowProvider)),
          labelIds: [...data.labelIds],
          // Reminder form: a new reminder is monthly from today.
          schedule:
              reminder?.schedule ??
              ReminderSchedule(
                frequency: ReminderFrequency.monthly,
                startDate: ref.read(todayProvider),
                nextDueAt: ref.read(todayProvider),
              ),
          autoPost: reminder?.autoPost ?? false,
          notify: reminder?.notify ?? false,
          refund: t?.type == TransactionType.expense && t!.amount.micros > 0,
        ),
      ),
    );
    final values = state.value;
    final errors = useState(const TransactionFormErrors());
    final saving = useState(false);
    final title = useTextEditingController(text: t?.title);
    final notes = useTextEditingController(text: t?.notes);
    final amount = useTextEditingController();
    final received = useTextEditingController();
    final rate = useTextEditingController();

    /// Assets accounts with their balances as they change: one created from
    /// the picker shows up at once.
    final live = {
      for (final a
          in ref.watch(assetsAccountsWithBalanceProvider).value ??
              const <AssetsAccountWithBalance>[])
        a.account.id: a,
    };
    AssetsAccount? accountOf(String? id) =>
        live[id]?.account ??
        data.assetsAccounts.where((a) => a.id == id).firstOrNull;
    String currencyOf(String? id) => accountOf(id)?.currency ?? '';

    String money(int micros, String currency) => formatMoney(
      micros,
      currency: currency,
      locale: l10n.localeName,
      symbol: false,
    );
    int? parse(TextEditingController field) =>
        parseMoney(field.text, locale: l10n.localeName);

    /// The rate is what the amount received is worth per unit sent, so each
    /// of the two fields fills the other.
    void syncRate() {
      final sent = parse(amount);
      final got = parse(received);
      if (sent == null || sent <= 0 || got == null || got <= 0) return;
      rate.text = money(
        _mulDiv(got, microsPerUnit, sent),
        currencyOf(state.value.toAssetsAccountId),
      );
    }

    void syncReceived() {
      final sent = parse(amount);
      final perUnit = parse(rate);
      if (sent == null || sent <= 0 || perUnit == null || perUnit <= 0) return;
      received.text = money(
        _mulDiv(sent, perUnit, microsPerUnit),
        currencyOf(state.value.toAssetsAccountId),
      );
    }

    useEffect(() {
      if (t != null) {
        amount.text = money(t.amount.micros.abs(), t.amount.currency);
        if (t.transfer?.amountReceived case final micros?) {
          received.text = money(micros, currencyOf(values.toAssetsAccountId));
          syncRate();
        }
      }
      return null;
    }, const []);
    // The rate shows as text: rebuild when it changes.
    useListenable(rate);

    /// A transfer whose destination holds another currency needs the amount
    /// received.
    bool crossCurrency(TransactionFormValues v) =>
        v.isTransfer &&
        v.toAssetsAccountId != null &&
        currencyOf(v.toAssetsAccountId) != currencyOf(v.assetsAccountId);

    void setType(TransactionType type) {
      if (type != TransactionType.transfer) {
        received.clear();
        rate.clear();
      }
      state.value = state.value.withType(type);
    }

    Future<void> pickCategory() async {
      final picked = await showCategoryPickerSheet(
        context,
        kind: state.value.type == TransactionType.income
            ? CategoryKind.income
            : CategoryKind.expense,
        selectedId: state.value.categoryId,
      );
      if (picked == null || !context.mounted) return;
      state.value = state.value.copyWith(categoryId: picked);
    }

    Future<void> pickAssetsAccount({required bool destination}) async {
      final v = state.value;
      final picked = await showAssetsAccountPickerSheet(
        context,
        selectedId: destination ? v.toAssetsAccountId : v.assetsAccountId,
        excludeId: destination ? v.assetsAccountId : v.toAssetsAccountId,
      );
      if (picked == null || !context.mounted) return;
      state.value = destination
          ? state.value.copyWith(toAssetsAccountId: picked)
          : state.value.copyWith(assetsAccountId: picked);
    }

    /// Typing the rate fills the amount received.
    Future<void> editRate() async {
      var typed = rate.text;
      final picked = await showLedgerDialog<String>(
        context: context,
        title: l10n.fieldRate,
        body: l10n.transactionRate(
          currencyOf(values.assetsAccountId),
          '?',
          currencyOf(values.toAssetsAccountId),
        ),
        extra: TextFormField(
          initialValue: typed,
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
      if (picked == null || !context.mounted) return;
      rate.text = picked;
      syncReceived();
    }

    void swap() {
      received.clear();
      rate.clear();
      state.value = state.value.swapped();
    }

    /// "Save and add another": keeps the type, assets accounts, category and
    /// date, clears what belongs to the saved transaction.
    void startAnother() {
      title.clear();
      notes.clear();
      amount.clear();
      received.clear();
      rate.clear();
      state.value = state.value.copyWith(
        labelIds: [],
        refund: false,
        suggestion: null,
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.transactionSaved)));
    }

    Future<void> save({required bool again}) async {
      final v = state.value;
      final sent = parse(amount);
      final cross = crossCurrency(v);
      final got = cross ? parse(received) : null;
      errors.value = TransactionFormErrors(
        amount: switch (sent) {
          null when amount.text.trim().isEmpty => l10n.errorAmountRequired,
          null => l10n.errorInvalidAmount,
          <= 0 => l10n.errorAmountRequired,
          _ => null,
        },
        title: title.text.trim().isEmpty ? l10n.errorTitleRequired : null,
        assetsAccount: v.assetsAccountId == null
            ? l10n.errorAssetsAccountRequired
            : null,
        destination: switch (v.toAssetsAccountId) {
          _ when !v.isTransfer => null,
          null => l10n.errorDestinationRequired,
          final id when id == v.assetsAccountId => l10n.errorDestinationSame,
          _ => null,
        },
        received: cross && (got == null || got <= 0)
            ? l10n.errorAmountReceivedRequired
            : null,
      );
      if (errors.value.any) return;

      saving.value = true;
      final draft = TransactionDraft(
        id: t?.id,
        type: v.type,
        // Wall clock: to the minute, no seconds and no time zone.
        occurredAt: DateTime(
          v.occurredAt.year,
          v.occurredAt.month,
          v.occurredAt.day,
          v.occurredAt.hour,
          v.occurredAt.minute,
        ),
        amount: v.type == TransactionType.expense && !v.refund ? -sent! : sent!,
        assetsAccountId: v.assetsAccountId!,
        toAssetsAccountId: v.isTransfer ? v.toAssetsAccountId : null,
        toAmount: got,
        categoryId: v.isTransfer ? null : v.categoryId,
        title: title.text.trim(),
        notes: notes.text.trim(),
        labelIds: v.labelIds,
        reminderId: t?.reminderId,
      );
      final repeats = !isReminder && v.repeat != ReminderFrequency.once;
      final result = isReminder
          ? await ref
                .read(remindersRepositoryProvider)
                .save(
                  ReminderDraft(
                    id: reminder?.id,
                    template: draft,
                    schedule: v.schedule,
                    autoPost: v.autoPost,
                    notify: v.notify,
                    isPaused: reminder?.isPaused ?? false,
                  ),
                )
          : repeats
          ? await ref
                .read(remindersRepositoryProvider)
                .saveRepeating(
                  draft,
                  v.repeat,
                  tomorrow: ref.read(tomorrowProvider),
                )
          : await ref.read(transactionsRepositoryProvider).save(draft);
      if (!context.mounted) return;
      saving.value = false;
      final messenger = ScaffoldMessenger.of(context);
      switch (result) {
        case Ok() when again:
          startAnother();
        case Ok():
          context.pop();
          if (repeats) {
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.reminderCreated)),
            );
          }
        case Err(:final error):
          messenger.showSnackBar(
            SnackBar(content: Text(transactionErrorMessage(error, l10n))),
          );
      }
    }

    Future<void> delete() async {
      final id = t!.id;
      final messenger = ScaffoldMessenger.of(context);
      final repository = ref.read(transactionsRepositoryProvider);
      await repository.trash(id);
      if (!context.mounted) return;
      context.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.transactionsMovedToTrash),
          action: SnackBarAction(
            label: l10n.actionUndo,
            onPressed: () => repository.restore(id),
          ),
        ),
      );
    }

    final categories = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    final groups = {
      for (final g
          in ref.watch(categoryGroupsProvider).value ?? const <CategoryGroup>[])
        g.id: g.name,
    };
    final category = categories[values.categoryId];
    final currency = currencyOf(values.assetsAccountId);
    final error = errors.value;

    /// "Wallet · EUR · €186.50".
    String accountValue(String? id) {
      final account = accountOf(id);
      if (account == null) return l10n.actionChoose;
      return l10n.assetsAccountSummary(
        account.name,
        account.currency,
        formatMoney(
          live[id]?.balance ?? 0,
          currency: account.currency,
          locale: l10n.localeName,
        ),
      );
    }

    final (String sign, Color color) = switch (values.type) {
      TransactionType.transfer => ('⇄', finance.transfer),
      TransactionType.income => ('+', finance.income),
      _ when values.refund => ('+', finance.income),
      _ => ('−', finance.expense),
    };
    final suggested = switch (values.suggestion) {
      null => null,
      final s when s.type == TransactionType.transfer => l10n.transferFromTo(
        accountOf(s.assetsAccountId)?.name ?? '',
        accountOf(s.toAssetsAccountId)?.name ?? '',
      ),
      final s => l10n.transactionSubtitle(
        categories[s.categoryId]?.name ?? l10n.categoryNone,
        accountOf(s.assetsAccountId)?.name ?? '',
      ),
    };
    final titleField = TransactionTitleField(
      controller: title,
      onSuggestion: (suggestion) => state.value = state.value.withSuggestion(
        suggestion,
        knownAssetsAccount: accountOf(suggestion.assetsAccountId) != null,
      ),
      suggested: suggested,
      error: error.title,
    );
    String stamp(DateTime utc) =>
        DateFormat.yMMMd(l10n.localeName).add_jm().format(utc.toLocal());

    return Scaffold(
      appBar: AppBar(
        title: Text(switch ((isReminder, t)) {
          (true, null) => l10n.editorNewReminder,
          (true, _) => l10n.editorEditReminder,
          (false, null) => l10n.editorNewTransaction,
          _ => l10n.editorEditTransaction,
        }),
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
            selected: values.type,
            onChanged: setType,
          ),
          TransactionAmountField(
            controller: amount,
            label: l10n.fieldAmount,
            currency: currency,
            color: color,
            sign: sign,
            error: error.amount,
          ),
          if (values.type == TransactionType.expense)
            TransactionRefundRow(
              value: values.refund,
              onChanged: (on) => state.value = state.value.copyWith(refund: on),
            ),
          if (values.isTransfer) ...[
            TransactionTransferFields(
              fromValue: accountValue(values.assetsAccountId),
              toValue: accountValue(values.toAssetsAccountId),
              onFrom: () => pickAssetsAccount(destination: false),
              onTo: () => pickAssetsAccount(destination: true),
              onSwap: swap,
              fromCurrency: currency,
              toCurrency: values.toAssetsAccountId == null
                  ? null
                  : currencyOf(values.toAssetsAccountId),
              received: received,
              onReceived: (_) => syncRate(),
              rate: rate.text,
              onEditRate: editRate,
              destinationError: error.destination,
              receivedError: error.received,
            ),
            titleField,
          ] else ...[
            titleField,
            EditorRow(
              icon: Icons.grid_view,
              label: l10n.fieldCategory,
              onTap: pickCategory,
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
              onTap: () => pickAssetsAccount(destination: false),
              child: Text(accountValue(values.assetsAccountId)),
            ),
          ],
          if (error.assetsAccount case final message?)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: FieldError(message),
            ),
          if (isReminder)
            TransactionReminderFields(
              values: values,
              isNew: reminder == null,
              onChanged: (v) => state.value = v,
            )
          else ...[
            TransactionDateTimeFields(
              dateTime: values.occurredAt,
              onChanged: (value) =>
                  state.value = state.value.copyWith(occurredAt: value),
            ),
            if (t == null)
              TransactionRepeatField(
                frequency: values.repeat,
                future: !values.occurredAt.isBefore(
                  ref.watch(tomorrowProvider),
                ),
                onChanged: (frequency) =>
                    state.value = state.value.copyWith(repeat: frequency),
              ),
          ],
          TransactionLabelsField(
            labelIds: values.labelIds,
            onChanged: (ids) =>
                state.value = state.value.copyWith(labelIds: ids),
          ),
          EditorRow(
            icon: Icons.article_outlined,
            label: l10n.fieldNotes,
            child: TextField(
              controller: notes,
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
          if (t != null && !isReminder)
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
      bottomNavigationBar: AboveKeyboard(
        child: TransactionFormActions(
          saving: saving.value,
          onSave: () => save(again: false),
          onSaveAndAddAnother: t == null && !isReminder
              ? () => save(again: true)
              : null,
          // A reminder is deleted from its own page.
          onDelete: t == null || isReminder ? null : delete,
        ),
      ),
    );
  }
}
