import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/repositories/setting_keys.dart';
import '../data/providers.dart';

part 'default_currency.g.dart';

/// ISO 4217 code preselected for new assets accounts and imports, the one
/// reports open in and the one of budgets. Never converts anything. Seeded on
/// first launch; the device region's currency until then.
@Riverpod(keepAlive: true)
class DefaultCurrency extends _$DefaultCurrency {
  @override
  Stream<String> build() => ref
      .watch(settingsRepositoryProvider)
      .watch(SettingKeys.defaultCurrency)
      .map(
        (code) => code ?? deviceCurrency(PlatformDispatcher.instance.locale),
      );

  /// Each assets account keeps its own currency.
  Future<void> set(String code) => ref
      .read(settingsRepositoryProvider)
      .set(SettingKeys.defaultCurrency, code);
}
