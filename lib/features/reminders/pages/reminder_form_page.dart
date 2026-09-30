import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/widgets/page_load_error.dart';
import '../../transactions/widgets/transaction_form.dart';
import '../providers/reminders_providers.dart';

/// Creates ([id] `null`) a reminder or edits every field of one: the
/// transaction form with a schedule.
class ReminderFormPage extends ConsumerWidget {
  const ReminderFormPage({super.key, this.id});

  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(reminderEditorDataProvider(id))) {
      AsyncValue(:final value?) => TransactionForm(data: value),
      AsyncError() => Scaffold(
        appBar: AppBar(),
        body: PageLoadError(providers: [reminderEditorDataProvider(id)]),
      ),
      _ => Scaffold(appBar: AppBar()),
    };
  }
}
