import 'package:flutter/material.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/app_logo.dart';

/// Top of the drawer: logo, app name and the privacy line.
class AppDrawerHeader extends StatelessWidget {
  const AppDrawerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppLogo(height: AppLogo.drawerHeight),
          const SizedBox(height: 12),
          Text(l10n.appTitle, style: text.headlineSmall),
          const SizedBox(height: 4),
          Text(l10n.appPrivacyLine, style: text.bodySmall),
        ],
      ),
    );
  }
}
