import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// A [SettingsRow] with a switch: the whole row toggles it.
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              spacing: 14,
              children: [
                Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.rowTitle),
                      if (subtitle != null)
                        Text(subtitle!, style: theme.textTheme.rowSubtitle),
                    ],
                  ),
                ),
                Switch(value: value, onChanged: onChanged),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
