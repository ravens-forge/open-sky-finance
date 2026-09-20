import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/repositories/setting_keys.dart';
import '../data/providers.dart';

part 'theme_mode.g.dart';

/// Light, dark or following the device.
@Riverpod(keepAlive: true)
class AppThemeMode extends _$AppThemeMode {
  @override
  Stream<ThemeMode> build() => ref
      .watch(settingsRepositoryProvider)
      .watch(SettingKeys.themeMode)
      .map((name) => ThemeMode.values.asNameMap()[name] ?? ThemeMode.system);

  Future<void> set(ThemeMode mode) => ref
      .read(settingsRepositoryProvider)
      .set(SettingKeys.themeMode, mode.name);
}
