import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_placeholder.dart';
import '../../../core/widgets/reorderable_sections.dart';
import '../../../data/models/home_section.dart';
import '../models/home_section_place.dart';
import '../providers/home_controller.dart';
import '../providers/home_providers.dart';
import '../widgets/home_section_view.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return switch (ref.watch(homeSectionsProvider)) {
      AsyncData(:final value) => _sections(context, ref, value),
      AsyncError() => Center(child: EmptyState(title: l10n.errorLoadFailed)),
      _ => PagePlaceholder(label: l10n.pageHome),
    };
  }

  Widget _sections(
    BuildContext context,
    WidgetRef ref,
    List<HomeSection> sections,
  ) {
    final l10n = context.l10n;
    final visible = [
      for (final s in sections)
        if (s.visible) s.id,
    ];
    if (visible.isEmpty) {
      return Center(
        child: EmptyState(
          title: l10n.homeAllHidden,
          actions: [
            OutlinedButton(
              onPressed: () => context.push(Routes.homeSections),
              child: Text(l10n.pageArrangeHome),
            ),
          ],
        ),
      );
    }
    final controller = ref.read(homeControllerProvider.notifier);
    void move(int from, int to) => controller.move(visible, from, to);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
      child: ReorderableSections(
        onReorder: move,
        children: [
          for (final (i, id) in visible.indexed)
            HomeSectionView(
              key: ValueKey(id),
              id: id,
              place: HomeSectionPlace(
                i,
                onMoveUp: i > 0 ? () => move(i, i - 1) : null,
                onMoveDown: i < visible.length - 1
                    ? () => move(i, i + 1)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
