import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
import '../../../data/providers.dart';
import '../../assets_accounts/providers/assets_accounts_providers.dart';
import '../../assets_accounts/widgets/assets_account_picker_sheet.dart';
import '../../categories/providers/categories_providers.dart';
import '../../categories/widgets/category_picker_sheet.dart';
import '../../transactions/models/transaction_error.dart';
import '../../transactions/widgets/transaction_form_actions.dart';
import '../models/reminder_labels.dart';
import '../providers/reminders_providers.dart';
import 'delete_reminder_dialog.dart';
import 'record_reminder.dart';
import 'reminder_header.dart';
import 'reminder_history_section.dart';
import 'reminder_notify_switch.dart';
import 'reminder_upcoming_section.dart';

class ReminderDetail extends HookConsumerWidget {
  const ReminderDetail({super.key, required this.reminder});

  final Reminder reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final r = reminder;
    final repository = ref.read(remindersRepositoryProvider);
    // Changed here and not saved yet; `null` shows the reminder as stored.
    final paused = useState<bool?>(null);
    final autoPostChange = useState<bool?>(null);
    final notify = useState<bool?>(null);
    final categoryId = useState<String?>(null);
    final assetsAccountId = useState<String?>(null);
    final saving = useState(false);

    void openForm() => context.push(Routes.editReminder(r.id));

    Future<void> pickCategory() async {
      final picked = await showCategoryPickerSheet(
        context,
        kind: r.type == TransactionType.income
            ? CategoryKind.income
            : CategoryKind.expense,
        selectedId: categoryId.value ?? r.categoryId,
      );
      if (picked != null) categoryId.value = picked;
    }

    Future<void> pickAssetsAccount() async {
      final picked = await showAssetsAccountPickerSheet(
        context,
        selectedId: assetsAccountId.value ?? r.assetsAccountId,
      );
      if (picked != null) assetsAccountId.value = picked;
    }

    Future<void> save() async {
      saving.value = true;
      final result = await repository.saveChanges(
        r,
        isPaused: paused.value ?? r.isPaused,
        autoPost: autoPostChange.value ?? r.autoPost,
        notify: notify.value ?? r.notify,
        assetsAccountId: assetsAccountId.value ?? r.assetsAccountId,
        categoryId: categoryId.value ?? r.categoryId,
      );
      if (!context.mounted) return;
      saving.value = false;
      switch (result) {
        case Ok():
          context.pop();
        case Err(:final error):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(transactionErrorMessage(error, l10n))),
          );
      }
    }

    Future<void> delete() async {
      if (!await showDeleteReminderDialog(context) || !context.mounted) return;
      context.pop();
      await repository.remove(r.id);
    }

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
    final category = categories[categoryId.value ?? r.categoryId];
    final account = accounts[assetsAccountId.value ?? r.assetsAccountId];
    final transfer = r.type == TransactionType.transfer;
    final autoPost = autoPostChange.value ?? r.autoPost;

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
            value: paused.value ?? r.isPaused,
            onChanged: (on) => paused.value = on,
          ),
          const Divider(),
          EditorRow(
            icon: Icons.paid_outlined,
            label: l10n.fieldAmount,
            onTap: openForm,
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
              onTap: pickCategory,
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
            onTap: transfer ? openForm : pickAssetsAccount,
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
            onTap: openForm,
            child: Text(reminderScheduleSummary(r.schedule, l10n)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.reminderAuto),
            subtitle: Text(
              autoPost ? l10n.reminderAutoOnHint : l10n.reminderAutoOffHint,
            ),
            value: autoPost,
            onChanged: (on) => autoPostChange.value = on,
          ),
          ReminderNotifySwitch(
            value: notify.value ?? r.notify,
            onChanged: (on) => notify.value = on,
          ),
          ReminderUpcomingSection(
            reminder: r,
            today: today,
            onRecord: () => recordReminder(context, ref, r),
            onSkip: () => repository.skip(r.id),
          ),
          ReminderHistorySection(
            recorded: recorded,
            onOpen: (transaction) =>
                context.push(Routes.transaction(transaction.id)),
          ),
        ],
      ),
      bottomNavigationBar: TransactionFormActions(
        saving: saving.value,
        onSave: save,
        onDelete: delete,
      ),
    );
  }
}
