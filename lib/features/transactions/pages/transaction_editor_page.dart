import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
class _OpeningBalanceRedirect extends HookWidget {
  const _OpeningBalanceRedirect({required this.assetsAccountId});

  final String assetsAccountId;

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.pushReplacement(Routes.editAssetsAccount(assetsAccountId));
        }
      });
      return null;
    }, const []);
    return Scaffold(appBar: AppBar());
  }
}
