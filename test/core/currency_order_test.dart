import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/core/money/currency_order.dart';
import 'package:open_sky_finance/core/money/format_money.dart';

void main() {
  test('the default currency first, then by code', () {
    expect(orderCurrencies(['USD', 'ARS', 'EUR', 'USD'], 'EUR'), [
      'EUR',
      'ARS',
      'USD',
    ]);
    expect(orderCurrencies(['USD', 'GBP'], 'EUR'), ['GBP', 'USD']);
  });

  test('totals drop zeros and are never converted', () {
    expect(
      totalsInOrder({
        'USD': 5,
        'EUR': 0,
        'GBP': -3,
      }, 'EUR').map((e) => (e.key, e.value)),
      [('GBP', -3), ('USD', 5)],
    );
  });

  test('all zero: zero in its first currency, or the default one', () {
    expect(totalsInOrder({'USD': 0}, 'EUR').single.key, 'USD');
    expect(totalsInOrder({}, 'EUR').single.key, 'EUR');
  });

  test('shared symbols are told apart by ISO code', () {
    expect(sharedSymbols(['USD', 'ARS', 'EUR', 'GBP'], 'en'), {'USD', 'ARS'});
    expect(sharedSymbols(['EUR', 'GBP'], 'en'), isEmpty);
    expect(
      formatMoney(1250000000000, currency: 'ARS', locale: 'en', code: true),
      'ARS 1,250,000.00',
    );
    expect(formatMoney(18000000, currency: 'CHF', locale: 'en'), 'CHF 18.00');
  });
}
