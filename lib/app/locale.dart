import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/repositories/setting_keys.dart';
import '../data/providers.dart';

part 'locale.g.dart';

/// Language chosen in Settings, or `null` to follow the device.
@Riverpod(keepAlive: true)
class UserLocale extends _$UserLocale {
  @override
  Stream<Locale?> build() => ref
      .watch(settingsRepositoryProvider)
      .watch(SettingKeys.locale)
      .map((code) => code == null ? null : Locale(code));

  Future<void> set(Locale? locale) => ref
      .read(settingsRepositoryProvider)
      .set(SettingKeys.locale, locale?.languageCode);
}
