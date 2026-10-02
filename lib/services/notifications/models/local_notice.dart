import 'package:flutter/foundation.dart';

/// A notification shown by the device itself, never sent from anywhere.
@immutable
class LocalNotice {
  const LocalNotice({
    required this.id,
    required this.title,
    required this.body,
    required this.route,
    this.at,
  });

  /// The same id replaces the notification shown before.
  final int id;
  final String title;
  final String body;

  /// The page a tap opens.
  final String route;

  /// Local wall-clock time it shows at; `null` shows it now.
  final DateTime? at;

  @override
  bool operator ==(Object other) =>
      other is LocalNotice &&
      other.id == id &&
      other.title == title &&
      other.body == body &&
      other.route == route &&
      other.at == at;

  @override
  int get hashCode => Object.hash(id, title, body, route, at);
}
