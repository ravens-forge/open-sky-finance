import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/logging.dart';
import '../data/repositories/setting_keys.dart';
import '../data/providers.dart';

part 'theme_mode.g.dart';

/// Light, dark or following the device.
@Riverpod(keepAlive: true)
class AppThemeMode extends _$AppThemeMode {
  static const _nightMode = MethodChannel('open_sky_finance/night_mode');

  @override
  Stream<ThemeMode> build() {
    // Android draws the splash screen before Flutter starts: it has to know
    // the theme of the next launch, a restore included.
    listenSelf((_, next) {
      if (next case AsyncData(:final value) when Platform.isAndroid) {
        _nightMode.invokeMethod<void>('set', value.name).catchError(Log.error);
      }
    });
    return ref
        .watch(settingsRepositoryProvider)
        .watch(SettingKeys.themeMode)
        .map((name) => ThemeMode.values.asNameMap()[name] ?? ThemeMode.system);
  }

  Future<void> set(ThemeMode mode) => ref
      .read(settingsRepositoryProvider)
      .set(SettingKeys.themeMode, mode.name);
}
