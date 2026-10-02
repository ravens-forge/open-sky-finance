import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/dates/year_month.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/setting_keys.dart';
import '../../budgets/models/budget_line.dart';

part 'budget_alerts_controller.g.dart';

/// Whether a notification says when a budget is used up, and which budgets
/// already said so this month.
@Riverpod(keepAlive: true)
class BudgetAlertsController extends _$BudgetAlertsController {
  @override
  Stream<bool> build() => ref
      .watch(settingsRepositoryProvider)
      .watch(SettingKeys.budgetAlerts)
      .map((v) => v == 'true');

  Future<void> setEnabled(bool enabled) => ref
      .read(settingsRepositoryProvider)
      .set(SettingKeys.budgetAlerts, enabled ? 'true' : null);

  /// The [lines] used up in [month] that were not alerted for it yet, now
  /// marked as alerted: each budget alerts once a month.
  Future<List<BudgetLine>> takeNew(
    List<BudgetLine> lines,
    YearMonth month,
  ) async {
    final settings = ref.read(settingsRepositoryProvider);
    final key = '${month.year}-${month.month}';
    final sent = <String, Object?>{
      ...?switch (await settings.get(SettingKeys.budgetAlertsSent)) {
        final text? => jsonDecode(text) as Map<String, Object?>,
        null => null,
      },
    };
    final fresh = [
      for (final line in lines)
        if (line.budget > 0 &&
            line.spent >= line.budget &&
            sent[line.id] != key)
          line,
    ];
    if (fresh.isEmpty) return fresh;
    for (final line in fresh) {
      sent[line.id] = key;
    }
    // Only this month's entries matter from now on.
    sent.removeWhere((_, v) => v != key);
    await settings.set(SettingKeys.budgetAlertsSent, jsonEncode(sent));
    return fresh;
  }
}
