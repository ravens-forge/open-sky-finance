import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../data/enums/transaction_type.dart';
import '../providers/transaction_editor_provider.dart';
import '../widgets/transaction_form.dart';
import '../../shell/widgets/page_load_error.dart';

/// Creates ([id] `null`) or edits a transaction.
class TransactionEditorPage extends ConsumerWidget {
  const TransactionEditorPage({
    super.key,
    this.id,
    this.type = TransactionType.income,
    this.date,
  });

  final String? id;

  /// The type a new transaction starts with.
  final TransactionType type;

  /// The day a new transaction starts on, today when `null`.
  final DateTime? date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(transactionEditorDataProvider(id, type))) {
      // An opening balance belongs to its assets account, not to this editor.
      AsyncValue(:final value?)
          when value.transaction?.type == TransactionType.openingBalance =>
        _OpeningBalanceRedirect(
          assetsAccountId: value.transaction!.assetsAccountId,
        ),
      AsyncValue(:final value?) => TransactionForm(data: value, date: date),
      AsyncError() => Scaffold(
        appBar: AppBar(),
        body: PageLoadError(
          providers: [transactionEditorDataProvider(id, type)],
        ),
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
