import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:open_sky_finance/core/widgets/chart_range.dart';

List<double> _ticks(ChartRange r) => [
  for (var v = r.min; v <= r.max + r.step / 2; v += r.step) v,
];

void main() {
  test('round steps, about four apart', () {
    final r = ChartRange.around(0, 3450);
    expect((r.min, r.max, r.step), (0.0, 4000.0, 1000.0));
    expect(ChartRange.around(0, 4).step, 1);
  });

  test('a narrow range never repeats a compact label', () {
    for (final (low, high) in [
      (3101.9, 3124.1),
      (1249990.0, 1250025.0),
      (999.0, 1003.0),
    ]) {
      final range = ChartRange.around(low, high);
      for (final locale in ['en', 'es', 'fr']) {
        final labels = _ticks(range)
            .map(NumberFormat.compact(locale: locale).format)
            .toList();
        expect(labels.toSet(), hasLength(labels.length), reason: '$labels');
      }
    }
  });

  test('a narrow range keeps the data inside', () {
    final range = ChartRange.around(3101.9, 3124.1);
    expect(range.min, lessThanOrEqualTo(3101.9));
    expect(range.max, greaterThanOrEqualTo(3124.1));
    expect(range.step, 10);
  });
}
