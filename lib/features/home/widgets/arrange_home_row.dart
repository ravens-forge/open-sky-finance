import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../app/theme.dart';
import '../../../core/finance_colors.dart';
import '../../../core/l10n.dart';
import '../../../core/labels.dart';
import '../../../core/widgets/reorderable_sections.dart';
import '../../../data/enums/home_section_id.dart';
import '../../../data/models/home_section.dart';

/// A section on Arrange Home: drag handle, icon, name and what it shows, and
/// its visibility checkbox.
class ArrangeHomeRow extends StatelessWidget {
  const ArrangeHomeRow({
    super.key,
    required this.section,
    required this.index,
    required this.onVisible,
    this.onMoveUp,
    this.onMoveDown,
  });

  final HomeSection section;
  final int index;
  final ValueChanged<bool> onVisible;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final finance = FinanceColors.of(context);
    final name = section.id.label(l10n);
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        spacing: 8,
        children: [
          Semantics(
            label: l10n.homeSectionMove(name),
            customSemanticsActions: {
              CustomSemanticsAction(label: l10n.actionMoveUp): ?onMoveUp,
              CustomSemanticsAction(label: l10n.actionMoveDown): ?onMoveDown,
            },
            child: SectionDragStart(
              index: index,
              child: SizedBox.square(
                dimension: 44,
                child: Icon(
                  Icons.drag_indicator,
                  size: 20,
                  color: finance.disabled,
                ),
              ),
            ),
          ),
          Icon(_icon(section.id), color: theme.colorScheme.primary),
          Expanded(
            child: SectionDragStart(
              index: index,
              delayed: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.rowTitle.copyWith(
                      fontWeight: FontWeight.w600,
                      color: section.visible ? null : finance.disabled,
                    ),
                  ),
                  Text(
                    section.id.description(l10n),
                    style: theme.textTheme.rowSubtitle,
                  ),
                ],
              ),
            ),
          ),
          Checkbox(
            value: section.visible,
            semanticLabel: l10n.arrangeHomeShow(name),
            onChanged: (on) => onVisible(on ?? false),
          ),
        ],
      ),
    );
  }

  static IconData _icon(HomeSectionId id) => switch (id) {
    HomeSectionId.favoriteAccounts => Icons.star_outline,
    HomeSectionId.summary => Icons.summarize_outlined,
    HomeSectionId.cashFlow => Icons.bar_chart,
    HomeSectionId.budgetSummary => Icons.pie_chart_outline,
    HomeSectionId.netIncome => Icons.align_vertical_bottom,
    HomeSectionId.netWorth => Icons.show_chart,
    HomeSectionId.upcomingReminders => Icons.event_repeat,
  };
}
