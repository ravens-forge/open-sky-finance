import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale.g.dart';

/// Language chosen in Settings, or `null` to follow the device.
@Riverpod(keepAlive: true)
class UserLocale extends _$UserLocale {
  @override
  Locale? build() => null;

  void set(Locale? locale) => state = locale;
}
