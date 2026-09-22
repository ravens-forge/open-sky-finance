import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/home_section_header.dart';
import '../models/home_section_place.dart';

/// A Home section: its header (drag handle, title, caption) over [child],
/// with a line below.
class HomeSectionFrame extends StatelessWidget {
  const HomeSectionFrame({
    super.key,
    required this.title,
    required this.place,
    required this.child,
    this.caption,
    this.eyebrow = false,
  });

  final String title;
  final HomeSectionPlace place;
  final Widget child;
  final Widget? caption;
  final bool eyebrow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            HomeSectionHeader(
              title: title,
              index: place.index,
              caption: caption,
              eyebrow: eyebrow,
              onMoveUp: place.onMoveUp,
              onMoveDown: place.onMoveDown,
              onHandleTap: () => context.push(Routes.homeSections),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
