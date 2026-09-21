import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/enums/transaction_type.dart';
import '../providers/transaction_editor_provider.dart';
import '../widgets/transaction_form.dart';

/// Creates ([id] `null`) or edits a transaction.
class TransactionEditorPage extends ConsumerWidget {
  const TransactionEditorPage({
    super.key,
    this.id,
    this.type = TransactionType.expense,
  });

  final String? id;

  /// The type a new transaction starts with.
  final TransactionType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(transactionEditorDataProvider(id, type))) {
      // An opening balance belongs to its assets account, not to this editor.
      AsyncData(:final value)
          when value.transaction?.type == TransactionType.openingBalance =>
        _OpeningBalanceRedirect(
          assetsAccountId: value.transaction!.assetsAccountId,
        ),
      AsyncData(:final value) => TransactionForm(data: value),
      AsyncError() => Scaffold(
        appBar: AppBar(),
        body: Center(child: EmptyState(title: context.l10n.errorLoadFailed)),
      ),
      _ => Scaffold(appBar: AppBar()),
    };
  }
}

/// Sends the user to the assets account editor, where opening balances live.
class _OpeningBalanceRedirect extends StatefulWidget {
  const _OpeningBalanceRedirect({required this.assetsAccountId});

  final String assetsAccountId;

  @override
  State<_OpeningBalanceRedirect> createState() =>
      _OpeningBalanceRedirectState();
}

class _OpeningBalanceRedirectState extends State<_OpeningBalanceRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.pushReplacement(
          Routes.editAssetsAccount(widget.assetsAccountId),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar());
}
