import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_placeholder.dart';
import '../../../core/widgets/reorderable_sections.dart';
import '../../../data/models/home_section.dart';
import '../providers/home_controller.dart';
import '../providers/home_providers.dart';
import '../widgets/arrange_home_row.dart';
import '../widgets/section_link.dart';

/// Every Home section in order with its visibility; changes are saved at once.
class ArrangeHomePage extends ConsumerWidget {
  const ArrangeHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pageArrangeHome),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: FilledButton(
              onPressed: () => Navigator.maybePop(context),
              child: Text(l10n.actionDone),
            ),
          ),
        ],
      ),
      body: switch (ref.watch(homeSectionsProvider)) {
        AsyncData(:final value) => _list(context, ref, value),
        AsyncError() => Center(child: EmptyState(title: l10n.errorLoadFailed)),
        _ => PagePlaceholder(label: l10n.pageArrangeHome),
      },
    );
  }

  Widget _list(
    BuildContext context,
    WidgetRef ref,
    List<HomeSection> sections,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final controller = ref.read(homeControllerProvider.notifier);
    final ids = [for (final s in sections) s.id];
    void move(int from, int to) => controller.move(ids, from, to);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              l10n.arrangeHomeIntro,
              style: theme.textTheme.bodyMedium!.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ReorderableSections(
            spacing: 8,
            onReorder: move,
            children: [
              for (final (i, s) in sections.indexed)
                ArrangeHomeRow(
                  key: ValueKey(s.id),
                  section: s,
                  index: i,
                  onVisible: (on) => controller.setVisible(s.id, on),
                  onMoveUp: i > 0 ? () => move(i, i - 1) : null,
                  onMoveDown: i < sections.length - 1
                      ? () => move(i, i + 1)
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 10),
          SectionLink(
            l10n.arrangeHomeReset,
            color: theme.colorScheme.primary,
            onPressed: controller.reset,
          ),
        ],
      ),
    );
  }
}
