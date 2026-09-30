import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/now.dart';
import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/money/format_money.dart';
import '../../../core/result.dart';
import '../../../core/widgets/editor_row.dart';
import '../../../data/enums/category_kind.dart';
import '../../../data/enums/transaction_type.dart';
import '../../../data/models/assets_account.dart';
import '../../../data/models/category.dart';
import '../../../data/models/category_group.dart';
import '../../../data/models/reminder.dart';
import '../../../data/models/transaction.dart';
import '../../assets_accounts/providers/assets_accounts_providers.dart';
import '../../assets_accounts/widgets/assets_account_picker_sheet.dart';
import '../../categories/providers/categories_providers.dart';
import '../../categories/widgets/category_picker_sheet.dart';
import '../../transactions/models/transaction_error.dart';
import '../../transactions/widgets/transaction_form_actions.dart';
import '../models/reminder_labels.dart';
import '../providers/reminders_controller.dart';
import '../providers/reminders_providers.dart';
import 'delete_reminder_dialog.dart';
import 'record_reminder.dart';
import 'reminder_header.dart';
import 'reminder_history_section.dart';
import 'reminder_upcoming_section.dart';

class ReminderDetail extends ConsumerStatefulWidget {
  const ReminderDetail({super.key, required this.reminder});

  final Reminder reminder;

  @override
  ConsumerState<ReminderDetail> createState() => _ReminderDetailState();
}

class _ReminderDetailState extends ConsumerState<ReminderDetail> {
  // Changed here and not saved yet; `null` shows the reminder as stored.
  bool? _paused;
  bool? _autoPost;
  String? _categoryId;
  String? _assetsAccountId;
  var _saving = false;

  Reminder get _reminder => widget.reminder;

  RemindersController get _controller =>
      ref.read(remindersControllerProvider.notifier);

  void _openForm() => context.push(Routes.editReminder(_reminder.id));

  Future<void> _pickCategory() async {
    final picked = await showCategoryPickerSheet(
      context,
      kind: _reminder.type == TransactionType.income
          ? CategoryKind.income
          : CategoryKind.expense,
      selectedId: _categoryId ?? _reminder.categoryId,
    );
    if (picked != null) setState(() => _categoryId = picked);
  }

  Future<void> _pickAssetsAccount() async {
    final picked = await showAssetsAccountPickerSheet(
      context,
      selectedId: _assetsAccountId ?? _reminder.assetsAccountId,
    );
    if (picked != null) setState(() => _assetsAccountId = picked);
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    setState(() => _saving = true);
    final result = await _controller.saveChanges(
      _reminder,
      isPaused: _paused ?? _reminder.isPaused,
      autoPost: _autoPost ?? _reminder.autoPost,
      assetsAccountId: _assetsAccountId ?? _reminder.assetsAccountId,
      categoryId: _categoryId ?? _reminder.categoryId,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok():
        context.pop();
      case Err(:final error):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(transactionErrorMessage(error, l10n))),
        );
    }
  }

  Future<void> _delete() async {
    final controller = _controller;
    final id = _reminder.id;
    if (!await showDeleteReminderDialog(context) || !mounted) return;
    context.pop();
    await controller.remove(id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final r = _reminder;
    final today = ref.watch(todayProvider);
    final categories = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    final groups = {
      for (final g
          in ref.watch(categoryGroupsProvider).value ?? const <CategoryGroup>[])
        g.id: g.name,
    };
    final accounts = {
      for (final a
          in ref.watch(assetsAccountsProvider).value ?? const <AssetsAccount>[])
        a.id: a,
    };
    final recorded =
        ref.watch(reminderHistoryProvider(r.id)).value ?? const <Transaction>[];
    final category = categories[_categoryId ?? r.categoryId];
    final account = accounts[_assetsAccountId ?? r.assetsAccountId];
    final transfer = r.type == TransactionType.transfer;
    final autoPost = _autoPost ?? r.autoPost;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editorEditReminder),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: theme.colorScheme.outline),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          ReminderHeader(reminder: r, category: category, today: today),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.pause),
            title: Text(l10n.reminderPause),
            subtitle: Text(l10n.reminderPauseHint),
            value: _paused ?? r.isPaused,
            onChanged: (on) => setState(() => _paused = on),
          ),
          const Divider(),
          EditorRow(
            icon: Icons.paid_outlined,
            label: l10n.fieldAmount,
            onTap: _openForm,
            child: Text(
              l10n.reminderDetails(
                // The typographic minus of every other amount.
                '${r.amount.micros < 0 ? '−' : ''}${formatMoney(r.amount.micros.abs(), currency: r.amount.currency, locale: l10n.localeName)}',
                r.type.label(l10n),
              ),
            ),
          ),
          if (!transfer)
            EditorRow(
              icon: Icons.grid_view,
              label: l10n.fieldCategory,
              onTap: _pickCategory,
              child: Text(
                category == null
                    ? l10n.categoryNone
                    : l10n.categoryInGroup(
                        groups[category.groupId] ?? '',
                        category.name,
                      ),
              ),
            ),
          EditorRow(
            icon: Icons.account_balance_outlined,
            label: l10n.fieldAssetsAccount,
            // Both sides of a transfer are chosen in the full form.
            onTap: transfer ? _openForm : _pickAssetsAccount,
            child: Text(
              transfer
                  ? l10n.transferFromTo(
                      account?.name ?? '',
                      accounts[r.transfer!.assetsAccountId]?.name ?? '',
                    )
                  : l10n.reminderDetails(
                      account?.name ?? '',
                      account?.currency ?? '',
                    ),
            ),
          ),
          EditorRow(
            icon: Icons.repeat,
            label: l10n.reminderSchedule,
            onTap: _openForm,
            child: Text(reminderScheduleSummary(r.schedule, l10n)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.reminderAuto),
            subtitle: Text(
              autoPost ? l10n.reminderAutoOnHint : l10n.reminderAutoOffHint,
            ),
            value: autoPost,
            onChanged: (on) => setState(() => _autoPost = on),
          ),
          ReminderUpcomingSection(
            reminder: r,
            today: today,
            onRecord: () => recordReminder(context, ref, r),
            onSkip: () => _controller.skip(r.id),
          ),
          ReminderHistorySection(
            recorded: recorded,
            onOpen: (transaction) =>
                context.push(Routes.transaction(transaction.id)),
          ),
        ],
      ),
      bottomNavigationBar: TransactionFormActions(
        saving: _saving,
        onSave: _save,
        onDelete: _delete,
      ),
    );
  }
}
