import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/widgets/page_load_error.dart';
import '../providers/budgets_providers.dart';
import '../widgets/edit_budgets_form.dart';

class EditBudgetsPage extends ConsumerWidget {
  const EditBudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(budgetEditorDataProvider)) {
      AsyncValue(:final value?) => EditBudgetsForm(data: value),
      AsyncError() => Scaffold(
        appBar: AppBar(),
        body: PageLoadError(providers: [budgetEditorDataProvider]),
      ),
      _ => Scaffold(appBar: AppBar()),
    };
  }
}
