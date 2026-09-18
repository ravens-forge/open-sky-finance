import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../finance_colors.dart';
import '../l10n.dart';

/// Drag handle, title and optional caption. With [index], drag by the handle
/// or long-press the title.
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    this.index,
    this.caption,
    this.info,
    this.onMoveUp,
    this.onMoveDown,
  });

  final String title;
  final int? index;
  final String? caption;
  final Widget? info;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

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
    Widget titleText = Text(title, style: text.headlineSmall);
    if (index != null) {
      handle = ReorderableDragStartListener(index: index!, child: handle);
      titleText = ReorderableDelayedDragStartListener(
        index: index!,
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
        if (caption != null) Text(caption!, style: text.bodySmall),
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
