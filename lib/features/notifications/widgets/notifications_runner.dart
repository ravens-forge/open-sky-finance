import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/now.dart';
import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../../../core/logging.dart';
import '../../../data/models/reminder.dart';
import '../../../services/notifications/models/local_notice.dart';
import '../../../services/notifications/models/notice_channel.dart';
import '../../../services/notifications/notifications_service.dart';
import '../../budgets/models/budget_overview.dart';
import '../../budgets/providers/budgets_providers.dart';
import '../../reminders/providers/reminders_providers.dart';
import '../models/reminder_notices.dart';
import '../providers/budget_alerts_controller.dart';

/// Keeps the scheduled reminder notifications in step with the reminders,
/// and shows a budget alert when spending reaches a budget, while budget
/// alerts are on. Taps open the page of the notification.
class NotificationsRunner extends ConsumerStatefulWidget {
  const NotificationsRunner({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationsRunner> createState() =>
      _NotificationsRunnerState();
}

class _NotificationsRunnerState extends ConsumerState<NotificationsRunner> {
  /// What was last scheduled: unchanged reminders reschedule nothing, and a
  /// user who never asks for a notification never opens the plugin.
  var _scheduled = const <LocalNotice>[];

  NotificationsService get _service => ref.read(notificationsServiceProvider);

  Future<void> _open() => _service.open((route) {
    if (mounted) context.go(route);
  });

  Future<void> _schedule(List<Reminder> reminders) async {
    final l10n = context.l10n;
    final notices = reminderNotices(reminders, ref.read(nowProvider), l10n);
    if (_sameAs(notices)) return;
    _scheduled = notices;
    try {
      await _open();
      await _service.schedule(notices, channelName: l10n.pageReminders);
    } catch (error, stackTrace) {
      Log.error(error, stackTrace);
    }
  }

  bool _sameAs(List<LocalNotice> notices) =>
      notices.length == _scheduled.length &&
      notices.indexed.every((e) => e.$2 == _scheduled[e.$1]);

  Future<void> _alert(BudgetOverview overview) async {
    final l10n = context.l10n;
    final fresh = await ref
        .read(budgetAlertsControllerProvider.notifier)
        .takeNew(overview.lines, ref.read(currentMonthProvider));
    if (fresh.isEmpty) return;
    try {
      await _open();
      for (final line in fresh) {
        await _service.show(
          LocalNotice(
            // Clear of the reminder ids, one per budget.
            id: 1000 + line.id.hashCode.abs() % 100000,
            title: l10n.budgetAlertTitle(line.name),
            body: l10n.budgetAlertBody,
            route: Routes.budgets,
          ),
          channel: NoticeChannel.budgetAlerts,
          channelName: l10n.budgetAlertsChannel,
        );
      }
    } catch (error, stackTrace) {
      Log.error(error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(remindersProvider, (_, next) {
      if (next case AsyncData(:final value)) _schedule(value);
    });
    if (ref.watch(budgetAlertsControllerProvider).value ?? false) {
      ref.listen(budgetOverviewProvider(ref.watch(currentMonthProvider)), (
        _,
        next,
      ) {
        if (next case AsyncData(:final value)) _alert(value);
      });
    }
    return widget.child;
  }
}
