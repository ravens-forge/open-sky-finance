import 'package:open_sky_finance/services/notifications/models/local_notice.dart';
import 'package:open_sky_finance/services/notifications/models/notice_channel.dart';
import 'package:open_sky_finance/services/notifications/notifications_service.dart';

/// Notifications kept in lists: [scheduled] is what is pending now, [shown]
/// every notification shown; [granted] answers the permission request.
class FakeNotifications implements NotificationsService {
  FakeNotifications({this.granted = true});

  bool granted;
  var opened = false;
  var scheduled = <LocalNotice>[];
  final shown = <LocalNotice>[];

  @override
  Future<void> open(void Function(String route) onOpen) async => opened = true;

  @override
  Future<bool> requestPermission() async => granted;

  @override
  Future<void> schedule(
    List<LocalNotice> notices, {
    required String channelName,
  }) async => scheduled = notices;

  @override
  Future<void> show(
    LocalNotice notice, {
    required NoticeChannel channel,
    required String channelName,
  }) async => shown.add(notice);
}
