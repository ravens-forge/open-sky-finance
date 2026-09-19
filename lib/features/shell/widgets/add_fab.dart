import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n.dart';

/// Extended "+ Add" button that opens the transaction editor.
class AddFab extends StatelessWidget {
  const AddFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => context.push(Routes.newTransaction()),
      icon: const Icon(Icons.add),
      label: Text(context.l10n.actionAdd),
    );
  }
}
