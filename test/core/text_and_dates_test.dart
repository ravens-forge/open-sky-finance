import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:open_sky_finance/core/dates/wall_clock.dart';
import 'package:open_sky_finance/core/dates/year_month.dart';
import 'package:open_sky_finance/core/text/sort_key.dart';

void main() {
  test('sortKey ignores case and accents', () {
    expect(sortKey('Électricité'), 'electricite');
    expect(sortKey('Ñandú'), 'nandu');
    expect(sortKey('Cœur'), 'coeur');
    expect(sortKey('Été'), 'ete'); // decomposed
    final names = [
      'ordenador',
      'Zoo',
      'Ñandú',
      'électricité',
      'Eau',
      'nube',
      'agua',
    ];
    names.sort((a, b) => sortKey(a).compareTo(sortKey(b)));
    expect(names, [
      'agua',
      'Eau',
      'électricité',
      'Ñandú',
      'nube',
      'ordenador',
      'Zoo',
    ]);
  });

  test('YearMonth ranges and arithmetic', () {
    final feb = YearMonth(2024, 2);
    expect(feb.start, DateTime(2024, 2));
    expect(feb.end, DateTime(2024, 3));
    expect(feb.daysInMonth, 29);
    expect(YearMonth(2026, 12).plus(1), YearMonth(2027, 1));
    expect(YearMonth(2026, 1).plus(-13), YearMonth(2024, 12));
    expect(YearMonth(2026, 13), YearMonth(2027, 1));
    expect(YearMonth.of(DateTime(2026, 9, 18, 10)), YearMonth(2026, 9));
    expect(YearMonth(2026, 9).contains(DateTime(2026, 9, 30, 23, 59)), isTrue);
    expect(YearMonth(2026, 9).contains(DateTime(2026, 10)), isFalse);
    expect(YearMonth(2025, 12).compareTo(YearMonth(2026, 1)), isNegative);
    expect(YearMonth(2026, 9).toString(), '2026-09');
  });

  test('wall-clock helpers', () {
    final date = DateTime(2026, 3, 14, 18, 30, 5, 123);
    expect(startOfDay(date), DateTime(2026, 3, 14));
    expect(endOfDay(date), DateTime(2026, 3, 14, 23, 59, 59, 999, 999));
    expect(formatWallClock(date), '2026-03-14T18:30:05');
    expect(
      parseWallClock('2026-03-14T18:30:05'),
      DateTime(2026, 3, 14, 18, 30, 5),
    );
    expect(
      parseWallClock('2026-03-14 18:30:05'),
      DateTime(2026, 3, 14, 18, 30, 5),
    );
    expect(parseWallClock('2026-03-14T18:30:05Z'), isNull);
    expect(parseWallClock('2026-03-14T18:30:05+02:00'), isNull);
    expect(parseWallClock('2026-03-14'), isNull);
  });

  test('capitalizeFirst for localized headings', () async {
    await initializeDateFormatting();
    String heading(String locale) =>
        capitalizeFirst(DateFormat.yMMMM(locale).format(DateTime(2026, 9)));
    expect(heading('en'), 'September 2026');
    expect(heading('es'), 'Septiembre de 2026');
    expect(heading('fr'), 'Septembre 2026');
    expect(capitalizeFirst(''), '');
    expect(capitalizeFirst('été'), 'Été');
  });
}
