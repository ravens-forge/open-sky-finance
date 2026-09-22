import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/now.dart';
import '../../../app/routes.dart';
import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/day_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/info_note.dart';
import '../../../core/widgets/page_placeholder.dart';
import '../../../data/models/assets_account.dart';
import '../../../data/models/category.dart';
import '../../assets_accounts/providers/assets_accounts_providers.dart';
import '../../categories/providers/categories_providers.dart';
import '../models/trash_day.dart';
import '../providers/trash_controller.dart';
import '../providers/trash_providers.dart';
import '../widgets/delete_permanently_dialog.dart';
import '../widgets/trash_row.dart';

class TrashPage extends ConsumerWidget {
  const TrashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final trash = ref.watch(trashProvider);
    final count =
        trash.value?.fold(0, (sum, d) => sum + d.transactions.length) ?? 0;

    Future<void> empty() async {
      if (await showDeletePermanentlyDialog(context, count: count)) {
        await ref.read(trashControllerProvider.notifier).empty();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pageTrash),
        actions: [
          if (count > 0)
            TextButton(
              onPressed: empty,
              style: TextButton.styleFrom(
                foregroundColor: FinanceColors.of(context).expense,
              ),
              child: Text(l10n.trashEmpty),
            ),
        ],
      ),
      body: switch (trash) {
        AsyncError() => Center(child: EmptyState(title: l10n.errorLoadFailed)),
        AsyncData(value: []) => Center(
          child: EmptyState(
            title: l10n.trashEmptyStateTitle,
            message: l10n.trashEmptyStateMessage,
            actions: [
              OutlinedButton(
                onPressed: () => context.go(Routes.transactions),
                child: Text(l10n.trashGoToTransactions),
              ),
            ],
          ),
        ),
        AsyncData(:final value) => _TrashList(days: value, count: count),
        _ => PagePlaceholder(label: l10n.pageTrash),
      },
    );
  }
}

class _TrashList extends ConsumerWidget {
  const _TrashList({required this.days, required this.count});

  final List<TrashDay> days;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final controller = ref.read(trashControllerProvider.notifier);
    final categories = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    final accounts = {
      for (final a
          in ref.watch(assetsAccountsProvider).value ?? const <AssetsAccount>[])
        a.id: a,
    };
    final today = ref.watch(todayProvider);

    String title(DateTime date) {
      if (date == today) return l10n.trashDeletedToday;
      final format = date.year == today.year
          ? DateFormat.MMMd(l10n.localeName)
          : DateFormat.yMMMd(l10n.localeName);
      return l10n.trashDeletedOn(format.format(date));
    }

    Future<void> delete(String id) async {
      if (await showDeletePermanentlyDialog(context)) {
        await controller.deletePermanently(id);
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        InfoNote(l10n.trashIntro),
        for (final day in days) ...[
          DayHeader(
            title: title(day.date),
            trailing: Text('${day.transactions.length}'),
          ),
          const SizedBox(height: 4),
          for (final t in day.transactions)
            TrashRow(
              key: ValueKey(t.id),
              transaction: t,
              categories: categories,
              assetsAccounts: accounts,
              onRestore: () => controller.restore(t.id),
              onDelete: () => delete(t.id),
            ),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: theme.colorScheme.onSurface)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Text(
              l10n.trashFooter(count),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }
}
