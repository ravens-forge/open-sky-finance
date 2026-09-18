import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/core/money/currency_converter.dart';

void main() {
  final converter = CurrencyConverter('EUR', {
    'USD': rate(100, 110), // 1 USD = 0.909… EUR
    'XXX': Decimal.parse('0.5'),
  });

  test('main currency only: exact, not approximate', () {
    final total = converter.convert({'EUR': 1234567});
    expect(total.amount, 1234567);
    expect(total.approximate, isFalse);
    expect(total.notIncluded, isEmpty);
  });

  test('converts with decimal arithmetic and marks it approximate', () {
    final total = converter.convert({'EUR': 1000000, 'USD': 110000000});
    expect(total.amount, 101000000);
    expect(total.approximate, isTrue);
  });

  test('sums before rounding half-even', () {
    expect(converter.convert({'XXX': 3}).amount, 2); // 1.5
    expect(converter.convert({'XXX': 5}).amount, 2); // 2.5
    expect(converter.convert({'XXX': -5}).amount, -2); // -2.5
    expect(converter.convert({'XXX': 7}).amount, 4); // 3.5
    expect(converter.convert({'XXX': 1, 'USD': 0}).amount, 0); // 0.5
  });

  test('currencies without a rate are listed, not added', () {
    final total = converter.convert({'EUR': 5, 'GBP': 7, 'JPY': 0});
    expect(total.amount, 5);
    expect(total.approximate, isFalse);
    expect(total.notIncluded, {'GBP': 7});
  });
}
