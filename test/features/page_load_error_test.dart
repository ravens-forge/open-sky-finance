import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/router.dart';
import 'package:open_sky_finance/app/routes.dart';
import 'package:open_sky_finance/features/trash/models/trash_day.dart';
import 'package:open_sky_finance/features/trash/providers/trash_providers.dart';

import '../pump_app.dart';

void main() {
  testWidgets('a page that fails to load offers Report a bug and Try again', (
    tester,
  ) async {
    var reads = 0;
    final router = (await pumpApp(
      tester,
      overrides: [
        // Fails the first time only.
        trashProvider.overrideWith(
          (ref) => reads++ == 0
              ? Stream<List<TrashDay>>.error(StateError('read'))
              : Stream.value(const <TrashDay>[]),
        ),
      ],
    )).read(routerProvider);
    router.go(Routes.trash);
    await settle(tester);
    expect(find.text("Couldn't load this page"), findsOneWidget);
    expect(find.textContaining('DB-READ'), findsOneWidget);

    await tester.tap(find.text('Report a bug'));
    await settle(tester);
    expect(router.state.uri.path, Routes.reportBug);

    router.pop();
    await settle(tester);
    await tester.tap(find.text('Try again'));
    await settle(tester);
    expect(find.text('The trash is empty'), findsOneWidget);
  });
}
