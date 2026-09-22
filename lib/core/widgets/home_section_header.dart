import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../finance_colors.dart';
import '../../app/theme.dart';
import '../l10n.dart';
import 'reorderable_sections.dart';

/// Drag handle, title and optional caption. With [index], drag by the handle
/// or long-press the title inside a [ReorderableSections].
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    this.index,
    this.caption,
    this.eyebrow = false,
    this.info,
    this.onMoveUp,
    this.onMoveDown,
    this.onHandleTap,
  });

  final String title;
  final int? index;
  final Widget? caption;

  /// A small uppercase title, like "FAVORITE ASSETS ACCOUNTS".
  final bool eyebrow;
  final Widget? info;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  /// E.g. opens Arrange Home.
  final VoidCallback? onHandleTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    Widget handle = SizedBox.square(
      dimension: 44,
      child: Icon(
        Icons.drag_indicator,
        size: 20,
        color: FinanceColors.of(context).disabled,
      ),
    );
    Widget titleText = eyebrow
        ? Text(title.toUpperCase(), style: text.eyebrow)
        : Text(title, style: text.sectionTitle);
    if (onHandleTap != null) {
      handle = GestureDetector(onTap: onHandleTap, child: handle);
    }
    if (index != null) {
      handle = SectionDragStart(index: index!, child: handle);
      titleText = SectionDragStart(
        index: index!,
        delayed: true,
        child: titleText,
      );
    }
    return Row(
      children: [
        Semantics(
          label: l10n.homeSectionMove(title),
          customSemanticsActions: {
            CustomSemanticsAction(label: l10n.actionMoveUp): ?onMoveUp,
            CustomSemanticsAction(label: l10n.actionMoveDown): ?onMoveDown,
          },
          child: Transform.translate(
            offset: const Offset(-12, 0),
            child: handle,
          ),
        ),
        Expanded(
          child: Transform.translate(
            offset: const Offset(-12, 0),
            child: Row(
              children: [
                Flexible(child: titleText),
                ?info,
              ],
            ),
          ),
        ),
        if (caption != null)
          DefaultTextStyle.merge(style: text.bodySmall, child: caption!),
      ],
    );
  }
}

Widget homeSectionProxyDecorator(
  Widget child,
  int index,
  Animation<double> animation,
) => AnimatedBuilder(
  animation: animation,
  child: child,
  builder: (context, child) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 6 * animation.value,
      color: scheme.surface,
      shape: Border.all(color: scheme.outline),
      child: child,
    );
  },
);
