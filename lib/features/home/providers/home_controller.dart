import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/dates/year_month.dart';
import '../../../core/reorder_ids.dart';
import '../../../data/enums/home_section_id.dart';
import '../../../data/models/home_section.dart';
import '../../../data/models/transaction_filter.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/setting_keys.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../transactions/providers/transactions_drill_down.dart';

part 'home_controller.g.dart';

@Riverpod(keepAlive: true)
class HomeController extends _$HomeController {
  @override
  FutureOr<void> build() {}

  SettingsRepository get _settings => ref.read(settingsRepositoryProvider);

  /// Moves [group]'s section at [from] to [to] (counted after removing it);
  /// sections outside [group], such as hidden ones on Home, keep their place.
  Future<void> move(List<HomeSectionId> group, int from, int to) async {
    final sections = await _settings.watchHomeSections().first;
    final byName = {for (final s in sections) s.id.name: s};
    final ids = reorderIds(
      [for (final s in sections) s.id.name],
      [for (final id in group) id.name],
      from,
      to,
    );
    await _settings.setHomeSections([for (final id in ids) byName[id]!]);
  }

  Future<void> setVisible(HomeSectionId id, bool visible) async {
    final sections = await _settings.watchHomeSections().first;
    await _settings.setHomeSections([
      for (final s in sections)
        s.id == id ? HomeSection(id, visible: visible) : s,
    ]);
  }

  /// Default order and visibility.
  Future<void> reset() => _settings.set(SettingKeys.homeSections, null);

  Future<void> setChartMonths(int months) =>
      _settings.set(SettingKeys.homeChartMonths, months == 12 ? '12' : null);

  /// Makes the Transactions tab open on [month]; the caller goes there.
  void drillDown(YearMonth month) => ref
      .read(transactionsDrillDownProvider.notifier)
      .show(month, const TransactionFilter());
}
