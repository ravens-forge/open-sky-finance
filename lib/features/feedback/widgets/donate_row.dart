import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/l10n.dart';

/// The one donation link, with a heart in a tinted circle.
class DonateRow extends StatelessWidget {
  const DonateRow({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            spacing: 14,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primaryContainer,
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Icon(
                  Icons.favorite_border,
                  size: 18,
                  color: scheme.primary,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.supportDonate,
                      style: theme.textTheme.rowTitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      l10n.supportDonateHint,
                      style: theme.textTheme.rowSubtitle,
                    ),
                  ],
                ),
              ),
              Icon(Icons.open_in_new, size: 18, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
