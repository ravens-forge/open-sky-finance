import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart' as tz;

import 'models/local_notice.dart';
import 'models/notice_channel.dart';

part 'notifications_service.g.dart';

/// Local notifications (`flutter_local_notifications`): scheduled and shown
/// by the device, with no server and no network. Opened lazily, so a user
/// who never turns one on never touches the plugin. Tests replace it.
class NotificationsService {
  NotificationsService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _ready;

  /// Schedules in UTC instants: no time zone database is needed, and a wall
  /// clock time is turned into its instant on the device. Named `UTC`, the
  /// one name Android and iOS both know.
  static final _utc = tz.Location('UTC', [tz.minTime], [0], [tz.TimeZone.UTC]);

  /// Prepares the plugin; [onOpen] gets the route of a tapped notification,
  /// also of the one that launched the app.
  Future<void> open(void Function(String route) onOpen) => _ready ??= () async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        // Permission is asked for when the user turns a notification on.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload case final route?) onOpen(route);
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      if (launch!.notificationResponse?.payload case final route?) {
        onOpen(route);
      }
    }
  }();

  /// Asks the system (Android 13+, iOS); `false` when refused.
  Future<bool> requestPermission() async {
    final granted = switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission(),
      TargetPlatform.iOS =>
        await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, sound: true, badge: false),
      _ => false,
    };
    return granted ?? false;
  }

  /// Replaces every scheduled notification with [notices].
  Future<void> schedule(
    List<LocalNotice> notices, {
    required String channelName,
  }) async {
    await _plugin.cancelAllPendingNotifications();
    for (final n in notices) {
      await _plugin.zonedSchedule(
        id: n.id,
        scheduledDate: tz.TZDateTime.from(n.at!, _utc),
        title: n.title,
        body: n.body,
        payload: n.route,
        notificationDetails: _details(NoticeChannel.reminders, channelName),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> show(
    LocalNotice notice, {
    required NoticeChannel channel,
    required String channelName,
  }) => _plugin.show(
    id: notice.id,
    title: notice.title,
    body: notice.body,
    payload: notice.route,
    notificationDetails: _details(channel, channelName),
  );

  static NotificationDetails _details(NoticeChannel channel, String name) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.name,
          name,
          // Titles are the user's own: hidden on the lock screen.
          visibility: NotificationVisibility.private,
        ),
        iOS: const DarwinNotificationDetails(),
      );
}

@Riverpod(keepAlive: true)
NotificationsService notificationsService(Ref ref) => NotificationsService();
