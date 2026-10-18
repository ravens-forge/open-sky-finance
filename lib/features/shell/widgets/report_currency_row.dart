import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/default_currency.dart';
import '../../../app/report_currency.dart';
import '../../../app/theme.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/currency_picker.dart';
import '../../../core/widgets/picker_row.dart';
import '../../../core/widgets/picker_sheet.dart';

/// "Currency" and the one reports show; a tap lists every currency the
/// non-hidden assets accounts use. Shown only when they use more than one.
class ReportCurrencyRow extends ConsumerWidget {
  const ReportCurrencyRow({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
  });

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final used = ref.watch(reportCurrenciesProvider).value ?? const {};
    final current = ref.watch(reportCurrencyProvider).value;
    final fallback = ref.watch(defaultCurrencyProvider).value;
    if (used.length < 2 || current == null) return const SizedBox.shrink();

    Future<void> choose() async {
      final picked = await showPickerSheet<String>(
        context,
        (context) => PickerSheet(
          title: l10n.reportCurrency,
          header: Text(
            l10n.reportCurrencyIntro,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          children: [
            for (final MapEntry(key: currency, value: count) in used.entries)
              PickerRow(
                title: currencyLabel(currency, l10n),
                subtitle: currency == fallback
                    ? l10n.reportCurrencyDefaultCount(count)
                    : l10n.reportCurrencyCount(count),
                selected: currency == current,
                onTap: () => Navigator.pop(context, currency),
              ),
          ],
        ),
      );
      if (picked != null) {
        ref.read(reportCurrencyChoiceProvider.notifier).pick(picked);
      }
    }

    return Padding(
      padding: padding,
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              l10n.reportCurrency.toUpperCase(),
              style: Theme.of(context).textTheme.eyebrow,
            ),
            TextButton.icon(
              onPressed: choose,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.expand_more, size: 16),
              label: Text(
                currencyLabel(current, l10n),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
