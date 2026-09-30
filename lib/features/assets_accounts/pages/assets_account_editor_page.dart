import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/assets_account_editor_provider.dart';
import '../widgets/assets_account_form.dart';
import '../../shell/widgets/page_load_error.dart';

/// Creates ([id] `null`) or edits an assets account.
class AssetsAccountEditorPage extends ConsumerWidget {
  const AssetsAccountEditorPage({super.key, this.id});

  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(assetsAccountEditorDataProvider(id))) {
      AsyncValue(:final value?) => AssetsAccountForm(data: value),
      AsyncError() => Scaffold(
        appBar: AppBar(),
        body: PageLoadError(providers: [assetsAccountEditorDataProvider(id)]),
      ),
      _ => Scaffold(appBar: AppBar()),
    };
  }
}
