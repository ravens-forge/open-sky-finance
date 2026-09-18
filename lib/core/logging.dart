import 'package:flutter/foundation.dart';

/// The app's only logger.
///
/// Never pass amounts, names, titles, notes, file paths or any other user data. In
/// release builds messages are dropped anyway: only error types and counts are logged.
abstract final class Log {
  static void debug(String message) {
    if (!kReleaseMode) debugPrint(message);
  }

  /// An error. Release builds log only its type, since exception messages can
  /// contain user data.
  static void error(Object error, [StackTrace? stackTrace]) {
    if (kReleaseMode) {
      debugPrint('error: ${error.runtimeType}');
    } else {
      debugPrint('error: $error');
      if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// How many times something happened, e.g. `Log.count('import.skippedRows', 3)`.
  /// [event] must be a fixed code, never built from user data.
  static void count(String event, int count) => debugPrint('$event: $count');
}
