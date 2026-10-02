import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../services/notifications/notifications_service.dart';

/// Asks the system for permission to notify; when refused, says where to
/// turn it on and returns `false`.
Future<bool> askNotificationPermission(
  BuildContext context,
  WidgetRef ref,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final message = context.l10n.notificationsDenied;
  final granted = await ref
      .read(notificationsServiceProvider)
      .requestPermission();
  if (!granted) messenger.showSnackBar(SnackBar(content: Text(message)));
  return granted;
}
