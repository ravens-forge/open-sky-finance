@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/core/result.dart';
import 'package:open_sky_finance/features/data_management/models/bluecoins_preview.dart';
import 'package:open_sky_finance/features/data_management/pages/bluecoins_preview_page.dart';
import 'package:open_sky_finance/features/data_management/widgets/bluecoins_error_dialog.dart';
import 'package:open_sky_finance/services/bluecoins/bluecoins_mapper.dart';
import 'package:open_sky_finance/services/bluecoins/bluecoins_reader.dart';
import 'package:open_sky_finance/services/bluecoins/models/bluecoins_import_error.dart';
import 'package:open_sky_finance/services/bluecoins/models/loaded_bluecoins.dart';

import '../pump_app.dart';
import '../services/bluecoins_fixture.dart';
import 'demo_data.dart';
import 'golden.dart';

NavigatorState _navigator(ProviderContainer container) =>
    container.read(routerProvider).routerDelegate.navigatorKey.currentState!;

/// The synthetic Bluecoins sample, as the preview shows it on [goldenNow].
BluecoinsPreview _preview() {
  final tables = switch (BluecoinsReader.read(bluecoinsFixture().path)) {
    Ok(:final value) => value,
    Err() => throw StateError('fixture'),
  };
  return BluecoinsPreview.of(
    LoadedBluecoins(
      fileName: 'bluecoins-2026-09-10.fydb',
      size: 4404019,
      import: BluecoinsMapper.map(tables, now: goldenNow, appVersion: '1.0.0'),
    ),
    before: DateTime(2026, 9, 18),
  );
}

void main() {
  appGolden(
    'import_bluecoins_preview',
    height: 1660,
    seed: seedDemo,
    act: (tester, container, l10n) async {
      final preview = _preview();
      _navigator(container).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => BluecoinsPreviewPage(preview: preview),
        ),
      );
      await settle(tester);
    },
  );

  appGolden(
    'import_bluecoins_error',
    seed: seedDemo,
    act: (tester, container, l10n) async {
      unawaited(container.read(routerProvider).push(Routes.backups));
      await settle(tester);
      unawaited(
        showBluecoinsErrorDialog(
          _navigator(container).context,
          const BluecoinsNotABackup(),
        ),
      );
      await settle(tester);
    },
  );
}
