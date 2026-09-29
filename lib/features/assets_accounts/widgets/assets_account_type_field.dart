import 'package:flutter/material.dart';

import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/widgets/segmented_filter.dart';
import '../../../data/enums/assets_account_type.dart';

/// Assets / Liabilities, then a chip per type of that side.
class AssetsAccountTypeField extends StatelessWidget {
  const AssetsAccountTypeField({
    super.key,
    required this.type,
    required this.onChanged,
  });

  final AssetsAccountType type;
  final ValueChanged<AssetsAccountType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final types = AssetsAccountType.values.where(
      (t) => t.isLiability == type.isLiability,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Text(l10n.fieldType, style: theme.textTheme.bodySmall),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: false, label: Text(l10n.assetsAccountsAssets)),
            ButtonSegment(
              value: true,
              label: Text(l10n.assetsAccountsLiabilities),
            ),
          ],
          selected: {type.isLiability},
          onSelectionChanged: (s) => onChanged(
            AssetsAccountType.values.firstWhere(
              (t) => t.isLiability == s.first,
            ),
          ),
        ),
        SegmentedFilter<AssetsAccountType>(
          options: [for (final t in types) (t, t.label(l10n))],
          selected: type,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
