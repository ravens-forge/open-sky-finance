import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/destructive_button.dart';
import '../../../data/models/assets_account.dart';
import '../../../data/providers.dart';
import '../models/delete_choice.dart';
import 'delete_assets_account_dialog.dart';

/// "Delete assets account" at the bottom of the editor, with what it removes.
class AssetsAccountDeleteSection extends ConsumerWidget {
  const AssetsAccountDeleteSection({
    super.key,
    required this.account,
    required this.transactionCount,
  });

  final AssetsAccount account;
  final int transactionCount;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(assetsAccountsRepositoryProvider);
    final usage = await repository.usage(account.id);
    if (!context.mounted) return;
    final choice = await showDeleteAssetsAccountDialog(
      context,
      name: account.name,
      usage: usage,
    );
    switch (choice) {
      case DeleteChoice.delete:
        await repository.remove(account.id);
        // The editor and, under it, the deleted assets account's page.
        if (context.mounted) {
          Navigator.of(context)
            ..pop()
            ..pop();
        }
      case DeleteChoice.hide:
        await repository.setHidden(account.id, true);
        if (context.mounted) context.pop();
      case null:
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        DestructiveButton(
          onPressed: () => _delete(context, ref),
          child: Text(l10n.assetsAccountDelete),
        ),
        Text(
          l10n.assetsAccountDeleteNote(transactionCount),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
