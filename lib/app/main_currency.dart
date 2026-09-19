import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/database/tables/setting_keys.dart';
import '../data/providers.dart';

part 'main_currency.g.dart';

/// ISO 4217 code totals are shown in. Seeded on first launch; the device
/// region's currency until then.
@Riverpod(keepAlive: true)
Stream<String> mainCurrency(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(SettingKeys.mainCurrency)
    .map((code) => code ?? deviceCurrency(PlatformDispatcher.instance.locale));
