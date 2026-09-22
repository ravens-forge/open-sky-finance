import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/finance_colors.dart';

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.color,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            spacing: 14,
            children: [
              Icon(
                icon,
                size: 22,
                color: color ?? theme.colorScheme.onSurfaceVariant,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.rowTitle.copyWith(color: color),
                    ),
                    if (subtitle != null)
                      Text(subtitle!, style: theme.textTheme.rowSubtitle),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: FinanceColors.of(context).disabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
