import 'package:flutter/material.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/info_note.dart';

class RemindersEmptyState extends StatelessWidget {
  const RemindersEmptyState({super.key, required this.onNew});

  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmptyState(
              title: l10n.remindersEmpty,
              message: l10n.remindersEmptyMessage,
              actions: [
                FilledButton.icon(
                  onPressed: onNew,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.editorNewReminder),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
              child: InfoNote(l10n.remindersEmptyTip),
            ),
          ],
        ),
      ),
    );
  }
}
