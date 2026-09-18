import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:open_sky_finance/core/money/format_money.dart';
import 'package:open_sky_finance/core/money/parse_money.dart';

void main() {
  group('formatMoney', () {
    // Built from intl's symbols, not hard-coded spaces (they change between versions).
    String expected(String locale, String number, {bool negative = false}) {
      final s = NumberFormat.decimalPattern(locale).symbols;
      final n = number.replaceAll(',', 'G').replaceAll('.', 'D');
      final digits = n
          .replaceAll('G', s.GROUP_SEP)
          .replaceAll('D', s.DECIMAL_SEP);
      final sign = negative ? s.MINUS_SIGN : '';
      return locale == 'en' ? '$sign€$digits' : '$sign$digits €';
    }

    for (final locale in ['en', 'es', 'fr']) {
      test('in $locale', () {
        String f(int micros) =>
            formatMoney(micros, currency: 'EUR', locale: locale);

        expect(f(1234567890000), expected(locale, '1,234,567.89'));
        expect(f(0), expected(locale, '0.00'));
        expect(f(-12500000), expected(locale, '12.50', negative: true));
        expect(f(-500000), expected(locale, '0.50', negative: true));
        expect(f(9000000000120000), expected(locale, '9,000,000,000.12'));
        expect(f(1234567), expected(locale, '1.234567'));
        expect(f(1230000), expected(locale, '1.23'));
      });
    }

    test('uses the currency decimals', () {
      expect(formatMoney(1500000000, currency: 'JPY', locale: 'en'), '¥1,500');
    });
  });

  group('parseMoney', () {
    int? en(String s) => parseMoney(s, locale: 'en');
    int? es(String s) => parseMoney(s, locale: 'es');
    int? fr(String s) => parseMoney(s, locale: 'fr');

    test('locale separators', () {
      expect(en('1,234.56'), 1234560000);
      expect(es('1.234,56'), 1234560000);
      expect(fr('1 234,56'), 1234560000);
      expect(fr('1 234,56'), 1234560000);
      expect(fr('1 234,56'), 1234560000);
      expect(en('1,234,567'), 1234567000000);
      expect(es('1.234'), 1234000000);
    });

    test('zero, negatives, symbols', () {
      expect(en('0'), 0);
      expect(fr('0,00'), 0);
      expect(en('-12.50'), -12500000);
      expect(es('−12,50'), -12500000);
      expect(en('€12.50'), 12500000);
      expect(en('-€12.50'), -12500000);
      expect(fr('12,50 €'), 12500000);
      expect(fr('-1 234,56 €'), -1234560000);
    });

    test('6 decimals, large values', () {
      expect(en('0.000001'), 1);
      expect(fr('0,123456'), 123456);
      expect(es('9.007.199.254,740991'), maxMicros);
      expect(en('9007199254.740992'), isNull);
      expect(en('99999999999999999999'), isNull);
      expect(en('1.1234567'), isNull);
    });

    test('tolerant other decimal separator', () {
      expect(es('12.5'), 12500000);
      expect(fr('12.5'), 12500000);
      expect(fr('12.50'), 12500000);
      expect(en('12,5'), 12500000);
      expect(fr('0.123'), 123000);
      expect(fr('.5'), 500000);
      expect(en('12.'), 12000000);
    });

    test('rejects ambiguous or invalid input', () {
      expect(fr('1.234'), isNull);
      expect(fr('1.234.567'), isNull);
      expect(en('1,234.5,6'), isNull);
      expect(en('1.234,56'), isNull);
      expect(es('1,234.56'), isNull);
      expect(fr('1.234,56'), isNull);
      expect(en('12,34,5'), isNull);
      expect(en(''), isNull);
      expect(en('-'), isNull);
      expect(en('.'), isNull);
      expect(en('12a'), isNull);
      expect(en('1e3'), isNull);
    });

    test('round-trips formatMoney output', () {
      for (final locale in ['en', 'es', 'fr']) {
        for (final micros in [0, 1, -12500000, 1234567890000, 1234567]) {
          final text = formatMoney(micros, currency: 'EUR', locale: locale);
          expect(parseMoney(text, locale: locale), micros, reason: text);
        }
      }
    });
  });
}
