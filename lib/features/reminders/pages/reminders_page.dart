import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/now.dart';
import '../../../app/routes.dart';
import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/info_tooltip.dart';
import '../../../core/widgets/page_placeholder.dart';
import '../../../core/widgets/segmented_filter.dart';
import '../../../core/widgets/warning_banner.dart';
import '../../../data/enums/reminder_status.dart';
import '../../../data/models/assets_account.dart';
import '../../../data/models/category.dart';
import '../../../data/models/reminder.dart';
import '../../assets_accounts/providers/assets_accounts_providers.dart';
import '../../categories/providers/categories_providers.dart';
import '../../shell/widgets/page_load_error.dart';
import '../models/reminder_sections.dart';
import '../providers/reminders_controller.dart';
import '../providers/reminders_providers.dart';
import '../widgets/record_reminder.dart';
import '../widgets/reminder_list_row.dart';
import '../widgets/reminder_section.dart';
import '../widgets/reminders_empty_state.dart';

/// Active · Paused · Finished; the active ones as Overdue, Next 30 days and
/// Later, with Record and Skip on each row.
class RemindersPage extends ConsumerStatefulWidget {
  const RemindersPage({super.key});

  @override
  ConsumerState<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends ConsumerState<RemindersPage> {
  var _status = ReminderStatus.active;

  void _new() => context.push(Routes.newReminder);

  @override
  Widget build(BuildContext context) {
    return switch (ref.watch(remindersProvider)) {
      AsyncError() => PageLoadError(providers: [remindersProvider]),
      AsyncValue(value: []) => RemindersEmptyState(onNew: _new),
      AsyncValue(:final value?) => _list(value),
      _ => PagePlaceholder(label: context.l10n.pageReminders),
    };
  }

  Widget _list(List<Reminder> reminders) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final today = ref.watch(todayProvider);
    final categories = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    final accounts = {
      for (final a
          in ref.watch(assetsAccountsProvider).value ?? const <AssetsAccount>[])
        a.id: a,
    };
    final shown = [
      for (final r in reminders)
        if (r.status == _status) r,
    ];
    String filter(ReminderStatus status, String label) {
      final count = reminders.where((r) => r.status == status).length;
      return count == 0 ? label : l10n.reminderDetails(label, '$count');
    }

    Widget row(Reminder reminder) => ReminderListRow(
      reminder: reminder,
      categories: categories,
      assetsAccounts: accounts,
      today: today,
      onRecord: () => recordReminder(context, ref, reminder),
      onSkip: () =>
          ref.read(remindersControllerProvider.notifier).skip(reminder.id),
      onTap: () => context.push(Routes.reminder(reminder.id)),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SegmentedFilter<ReminderStatus>(
                options: [
                  (
                    ReminderStatus.active,
                    filter(ReminderStatus.active, l10n.remindersFilterActive),
                  ),
                  (
                    ReminderStatus.paused,
                    filter(ReminderStatus.paused, l10n.remindersFilterPaused),
                  ),
                  (
                    ReminderStatus.finished,
                    filter(
                      ReminderStatus.finished,
                      l10n.remindersFilterFinished,
                    ),
                  ),
                ],
                selected: _status,
                onChanged: (status) => setState(() => _status = status),
              ),
            ),
            Semantics(
              label: l10n.editorNewReminder,
              button: true,
              excludeSemantics: true,
              child: TextButton.icon(
                onPressed: _new,
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.remindersNew),
                // Narrow, so the three filters fit on its line.
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsetsDirectional.only(start: 8, end: 4),
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
          ],
        ),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(
              l10n.remindersEmptyFilter,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else if (_status == ReminderStatus.active)
          ..._sections(ReminderSections.of(shown, today), row)
        else
          for (final (i, reminder) in shown.indexed) ...[
            if (i > 0) const Divider(),
            row(reminder),
          ],
      ],
    );
  }

  List<Widget> _sections(
    ReminderSections sections,
    Widget Function(Reminder) row,
  ) {
    final l10n = context.l10n;
    final overdue = sections.overdue.length;
    // Explains scheduled amounts where they are listed: on "Next 30 days", or
    // on the first section when nothing is due that soon.
    final info = InfoTooltip(
      label: l10n.remindersInfoLabel,
      eyebrow: l10n.remindersInfoEyebrow.toUpperCase(),
      text: l10n.remindersInfo,
    );
    final infoOnFirst = sections.next.isEmpty;
    return [
      if (overdue > 0) ...[
        const SizedBox(height: 16),
        WarningBanner(
          lead: l10n.remindersOverdueLead(overdue),
          text: l10n.remindersOverdueText(overdue),
        ),
        ReminderSection(
          title: l10n.chipOverdue,
          color: FinanceColors.of(context).warning,
          info: infoOnFirst ? info : null,
          rows: [for (final r in sections.overdue) row(r)],
        ),
      ],
      if (sections.next.isNotEmpty)
        ReminderSection(
          title: l10n.remindersSectionNext30,
          info: info,
          rows: [for (final r in sections.next) row(r)],
        ),
      if (sections.later.isNotEmpty)
        ReminderSection(
          title: l10n.remindersSectionLater,
          info: infoOnFirst && overdue == 0 ? info : null,
          rows: [for (final r in sections.later) row(r)],
        ),
    ];
  }
}
