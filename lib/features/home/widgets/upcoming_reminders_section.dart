import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/now.dart';
import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../models/home_section_place.dart';
import '../providers/home_providers.dart';
import 'chart_empty_note.dart';
import 'home_section_frame.dart';
import 'section_link.dart';
import 'upcoming_reminder_row.dart';

class UpcomingRemindersSection extends ConsumerWidget {
  const UpcomingRemindersSection({super.key, required this.place});

  final HomeSectionPlace place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final reminders = ref.watch(homeUpcomingRemindersProvider).value;
    final today = ref.watch(todayProvider);
    return HomeSectionFrame(
      title: l10n.homeSectionUpcomingReminders,
      place: place,
      caption: SectionLink(
        l10n.homeRemindersAll,
        onPressed: () => context.go(Routes.reminders),
      ),
      child: switch (reminders) {
        null => const SizedBox(height: 56),
        [] => ChartEmptyNote(l10n.homeRemindersEmpty),
        final reminders => Column(
          children: [
            for (final r in reminders)
              UpcomingReminderRow(
                reminder: r,
                today: today,
                onTap: () => context.push(Routes.reminder(r.id)),
              ),
          ],
        ),
      },
    );
  }
}
