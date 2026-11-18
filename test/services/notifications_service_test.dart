import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/services/notifications/models/local_notice.dart';
import 'package:open_sky_finance/services/notifications/models/notice_channel.dart';
import 'package:open_sky_finance/services/notifications/notifications_service.dart';

/// The plugin as a list of the [calls] it got; [launch] is the notification
/// that opened the app, if any.
class _Plugin implements FlutterLocalNotificationsPlugin {
  final calls = <Invocation>[];
  NotificationAppLaunchDetails? launch;

  Iterable<Symbol> get names => calls.map((call) => call.memberName);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation);
    return switch (invocation.memberName) {
      #initialize => Future<bool?>.value(true),
      #getNotificationAppLaunchDetails =>
        Future<NotificationAppLaunchDetails?>.value(launch),
      _ => Future<void>.value(),
    };
  }
}

const _rent = LocalNotice(
  id: 7,
  title: 'Rent',
  body: 'Due today',
  route: '/reminders/rent',
);

void main() {
  test('opens the plugin once and passes on the route of a tapped '
      'notification, also of the one that launched the app', () async {
    final plugin = _Plugin()
      ..launch = const NotificationAppLaunchDetails(
        true,
        notificationResponse: NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: '/reminders/rent',
        ),
      );
    final service = NotificationsService(plugin);
    final routes = <String>[];

    await service.open(routes.add);
    await service.open(routes.add);
    expect(plugin.names.where((name) => name == #initialize), hasLength(1));
    expect(routes, ['/reminders/rent']);

    final onTap =
        plugin.calls.first.namedArguments[#onDidReceiveNotificationResponse]
            as void Function(NotificationResponse);
    onTap(
      const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: '/budgets',
      ),
    );
    // Nothing to open without a route.
    onTap(
      const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
      ),
    );
    expect(routes, ['/reminders/rent', '/budgets']);
  });

  test('a launch from the icon opens no page', () async {
    final plugin = _Plugin()
      ..launch = const NotificationAppLaunchDetails(false);
    final routes = <String>[];
    await NotificationsService(plugin).open(routes.add);
    expect(routes, isEmpty);
  });

  test('schedule replaces what was pending, at the instant of the wall '
      'clock time, with the title hidden on the lock screen', () async {
    final plugin = _Plugin();
    final at = DateTime(2026, 9, 17, 9);
    await NotificationsService(plugin).schedule([
      LocalNotice(
        id: _rent.id,
        title: _rent.title,
        body: _rent.body,
        route: _rent.route,
        at: at,
      ),
    ], channelName: 'Reminders');

    expect(plugin.names, [#cancelAllPendingNotifications, #zonedSchedule]);
    final scheduled = plugin.calls.last.namedArguments;
    expect(scheduled[#id], 7);
    expect(scheduled[#title], 'Rent');
    expect(scheduled[#payload], '/reminders/rent');
    final date = scheduled[#scheduledDate] as DateTime;
    expect(date.timeZoneOffset, Duration.zero);
    expect(date.isAtSameMomentAs(at), isTrue);
    final android =
        (scheduled[#notificationDetails] as NotificationDetails).android!;
    expect(android.channelId, 'reminders');
    expect(android.channelName, 'Reminders');
    expect(android.visibility, NotificationVisibility.private);
  });

  test('show uses the channel it is given', () async {
    final plugin = _Plugin();
    await NotificationsService(plugin).show(
      _rent,
      channel: NoticeChannel.budgetAlerts,
      channelName: 'Budget alerts',
    );

    final shown = plugin.calls.single;
    expect(shown.memberName, #show);
    expect(shown.namedArguments[#payload], '/reminders/rent');
    final android =
        (shown.namedArguments[#notificationDetails] as NotificationDetails)
            .android!;
    expect(android.channelId, 'budgetAlerts');
    expect(android.visibility, NotificationVisibility.private);
  });
}
