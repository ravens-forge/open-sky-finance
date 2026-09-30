import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../shell/widgets/page_load_error.dart';
import '../providers/reminders_providers.dart';
import '../widgets/reminder_detail.dart';

/// A reminder with what it has coming and what it recorded.
class ReminderPage extends ConsumerWidget {
  const ReminderPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = Text(context.l10n.editorEditReminder);
    return switch (ref.watch(reminderProvider(id))) {
      AsyncValue(:final value?) => ReminderDetail(reminder: value),
      AsyncError() => Scaffold(
        appBar: AppBar(title: title),
        body: PageLoadError(providers: [reminderProvider(id)]),
      ),
      // Loading, or just deleted and about to close.
      _ => Scaffold(appBar: AppBar(title: title)),
    };
  }
}
