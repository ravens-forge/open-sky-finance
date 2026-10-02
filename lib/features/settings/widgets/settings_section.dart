import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// An uppercase heading over an ink rule, then [children] split by hairlines.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.info,
  });

  final String title;
  final List<Widget> children;

  /// An [InfoTooltip] after the title.
  final Widget? info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.only(top: 22, bottom: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outline),
            ),
          ),
          child: Row(
            children: [
              Flexible(
                child: Semantics(
                  header: true,
                  child: Text(
                    title.toUpperCase(),
                    style: theme.textTheme.eyebrow,
                  ),
                ),
              ),
              // Its 48 px target overflows the heading instead of growing it.
              if (info != null)
                SizedBox(
                  width: 36,
                  height: 18,
                  child: OverflowBox(maxWidth: 48, maxHeight: 48, child: info),
                ),
            ],
          ),
        ),
        for (final (i, child) in children.indexed) ...[
          if (i > 0) const Divider(),
          child,
        ],
      ],
    );
  }
}
