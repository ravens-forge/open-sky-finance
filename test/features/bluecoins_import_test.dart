import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/theme.dart';
import 'package:open_sky_finance/core/l10n.dart';
import 'package:open_sky_finance/core/result.dart';
import 'package:open_sky_finance/features/data_management/models/bluecoins_preview.dart';
import 'package:open_sky_finance/features/data_management/models/restore_choice.dart';
import 'package:open_sky_finance/features/data_management/pages/bluecoins_preview_page.dart';
import 'package:open_sky_finance/services/bluecoins/bluecoins_mapper.dart';
import 'package:open_sky_finance/services/bluecoins/bluecoins_reader.dart';
import 'package:open_sky_finance/services/bluecoins/models/bluecoins_import_error.dart';
import 'package:open_sky_finance/services/bluecoins/models/bluecoins_tables.dart';
import 'package:open_sky_finance/services/bluecoins/models/loaded_bluecoins.dart';

import '../services/bluecoins_fixture.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

BluecoinsPreview _preview() => BluecoinsPreview.of(
  LoadedBluecoins(
    fileName: 'sample.fydb',
    size: 1000,
    import: BluecoinsMapper.map(
      (BluecoinsReader.read(
        bluecoinsFixture().path,
      ) as Ok<BluecoinsTables, BluecoinsImportError>).value,
      now: DateTime(2026, 9, 17),
      appVersion: '1.0.0',
    ),
  ),
  before: DateTime(2026, 9, 18),
);

/// Opens the preview from a button and returns what it popped with.
Future<RestoreChoice? Function()> _open(WidgetTester tester) async {
  RestoreChoice? choice;
  final preview = _preview();
  // Tall enough for the whole list, which is built lazily.
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(390, 2400);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => choice = await Navigator.push(
            context,
            MaterialPageRoute<RestoreChoice>(
              builder: (_) => BluecoinsPreviewPage(preview: preview),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return () => choice;
}

void main() {
  test('the preview counts what the snapshot holds', () {
    final preview = _preview();
    expect(preview.transactions, 7);
    expect(preview.transfers, 2);
    expect(preview.first, DateTime(2026));
    expect(preview.last, DateTime(2027, 1, 15, 8, 15));
    expect(preview.balances.map((b) => b.balance), [
      2774500000,
      87000000,
      -280000000,
      500000000,
      100000000,
      -50000000,
    ]);
  });

  testWidgets('shows three balances until asked for all', (tester) async {
    await _open(tester);
    expect(find.text('Test Card'), findsOneWidget);
    expect(find.text('Old Savings'), findsNothing);
    await tester.tap(find.text(_l10n.bluecoinsShowAll(6)));
    await tester.pumpAndSettle();
    expect(find.text('Old Savings'), findsOneWidget);
    expect(find.text(_l10n.bluecoinsShowAll(6)), findsNothing);
  });

  testWidgets('Replace and import, Change and Cancel', (tester) async {
    for (final (label, expected) in [
      (_l10n.bluecoinsAction, RestoreChoice.restore),
      (_l10n.restoreChangeFile, RestoreChoice.change),
      (_l10n.actionCancel, null),
    ]) {
      final choice = await _open(tester);
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(choice(), expected, reason: label);
    }
  });
}
