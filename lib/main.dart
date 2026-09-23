import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/logging.dart';
import 'services/backup/backup_service.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    for (final font in ['Newsreader', 'PublicSans']) {
      yield LicenseEntryWithLineBreaks([
        font,
      ], await rootBundle.loadString('assets/fonts/$font-OFL.txt'));
    }
  });
  final container = ProviderContainer();
  runApp(UncontrolledProviderScope(container: container, child: const App()));
  // A file left for the share sheet when the app was killed while sharing.
  unawaited(
    container
        .read(backupServiceProvider.future)
        .then((service) => service.deleteShareCopies())
        .catchError(Log.error),
  );
}
