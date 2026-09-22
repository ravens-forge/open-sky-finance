import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/app/now.dart';
import 'package:open_sky_finance/core/dates/year_month.dart';

void main() {
  test('day and month providers change only when the day or month does', () {
    var clock = DateTime(2026, 9, 30, 23, 58);
    final container = ProviderContainer(
      overrides: [nowProvider.overrideWith((ref) => clock)],
    );
    addTearDown(container.dispose);
    final days = <DateTime>[];
    final months = <YearMonth>[];
    container.listen(todayProvider, (_, day) => days.add(day));
    container.listen(currentMonthProvider, (_, month) => months.add(month));
    expect(container.read(tomorrowProvider), DateTime(2026, 10, 1));

    void tick(DateTime next) {
      clock = next;
      container.invalidate(nowProvider);
      container.read(todayProvider);
      container.read(currentMonthProvider);
    }

    tick(DateTime(2026, 9, 30, 23, 59));
    expect(days, isEmpty);
    expect(months, isEmpty);

    tick(DateTime(2026, 10, 1, 0, 0));
    expect(days, [DateTime(2026, 10, 1)]);
    expect(months, [YearMonth(2026, 10)]);
    expect(container.read(tomorrowProvider), DateTime(2026, 10, 2));
  });
}
