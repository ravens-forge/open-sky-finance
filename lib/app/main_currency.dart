import 'dart:ui';

import 'package:decimal/decimal.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/money/currency_converter.dart';
import '../data/repositories/setting_keys.dart';
import '../data/providers.dart';
import 'now.dart';

part 'main_currency.g.dart';

/// ISO 4217 code totals are shown in. Seeded on first launch; the device
/// region's currency until then.
@Riverpod(keepAlive: true)
class MainCurrency extends _$MainCurrency {
  @override
  Stream<String> build() => ref
      .watch(settingsRepositoryProvider)
      .watch(SettingKeys.mainCurrency)
      .map(
        (code) => code ?? deviceCurrency(PlatformDispatcher.instance.locale),
      );

  /// Each assets account keeps its own currency.
  Future<void> set(String code) =>
      ref.read(settingsRepositoryProvider).set(SettingKeys.mainCurrency, code);
}

/// Units of the main currency per unit of each other currency, as of today.
@riverpod
Stream<Map<String, Decimal>> exchangeRates(Ref ref) async* {
  final tomorrow = ref.watch(tomorrowProvider);
  final main = await ref.watch(mainCurrencyProvider.future);
  yield* ref.watch(exchangeRatesRepositoryProvider).watchRates(main, tomorrow);
}

/// Converts totals of any currency into the main one.
@riverpod
Future<CurrencyConverter> currencyConverter(Ref ref) async => CurrencyConverter(
  await ref.watch(mainCurrencyProvider.future),
  await ref.watch(exchangeRatesProvider.future),
);
