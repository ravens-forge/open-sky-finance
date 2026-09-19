import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/database/tables/setting_keys.dart';
import '../data/providers.dart';

part 'first_day_of_week.g.dart';

/// [DateTime.monday]…[DateTime.sunday], or `null` for the locale's default.
@Riverpod(keepAlive: true)
class FirstDayOfWeek extends _$FirstDayOfWeek {
  @override
  Stream<int?> build() => ref
      .watch(settingsRepositoryProvider)
      .watch(SettingKeys.firstDayOfWeek)
      .map((day) => day == null ? null : int.tryParse(day));

  Future<void> set(int day) => ref
      .read(settingsRepositoryProvider)
      .set(SettingKeys.firstDayOfWeek, '$day');
}
