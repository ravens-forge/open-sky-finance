import 'package:flutter/material.dart';

import '../l10n.dart';
import 'empty_state.dart';

/// Shown for an unknown path or an ID that no longer exists.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key, required this.onHome});

  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          child: EmptyState(
            title: l10n.notFoundTitle,
            message: l10n.notFoundMessage,
            actions: [
              FilledButton(onPressed: onHome, child: Text(l10n.actionGoHome)),
            ],
          ),
        ),
      ),
    );
  }
}
