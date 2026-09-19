import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n.dart';
import '../../../core/money/format_money.dart';
import '../../../core/widgets/info_tooltip.dart';
import '../models/credit_usage.dart';
import 'credit_usage_bar.dart';

/// "Credit used 22.7% of €3,000.00" with its info tooltip, the bar and what
/// is left.
class CreditUsageSection extends StatelessWidget {
  const CreditUsageSection({
    super.key,
    required this.usage,
    required this.currency,
  });

  final CreditUsage usage;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    String money(int micros) =>
        formatMoney(micros, currency: currency, locale: l10n.localeName);
    final percent = NumberFormat.decimalPercentPattern(
      locale: l10n.localeName,
      decimalDigits: 1,
    ).format(usage.used / usage.limit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              l10n.assetsAccountCreditUsed,
              style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
            ),
            InfoTooltip(
              label: l10n.assetsAccountCreditInfoLabel,
              text: l10n.assetsAccountCreditInfo,
            ),
            const Spacer(),
            Text(
              l10n.assetsAccountCreditUsedOf(percent, money(usage.limit)),
              style: text.bodySmall,
            ),
          ],
        ),
        CreditUsageBar(usage),
        const SizedBox(height: 6),
        Text(
          l10n.assetsAccountCreditAvailable(money(usage.available)),
          style: text.bodySmall,
        ),
      ],
    );
  }
}
