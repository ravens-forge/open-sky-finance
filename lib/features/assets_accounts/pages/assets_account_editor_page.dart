import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/assets_account_editor_provider.dart';
import '../widgets/assets_account_form.dart';

/// Creates ([id] `null`) or edits an assets account.
class AssetsAccountEditorPage extends ConsumerWidget {
  const AssetsAccountEditorPage({super.key, this.id});

  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(assetsAccountEditorDataProvider(id))) {
      AsyncData(:final value) => AssetsAccountForm(data: value),
      AsyncError() => Scaffold(
        appBar: AppBar(),
        body: Center(child: EmptyState(title: context.l10n.errorLoadFailed)),
      ),
      _ => Scaffold(appBar: AppBar()),
    };
  }
}
