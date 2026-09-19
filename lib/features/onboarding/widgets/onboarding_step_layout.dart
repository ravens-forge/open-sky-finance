import 'package:flutter/material.dart';

/// A step's scrollable content above its bottom buttons.
class OnboardingStepLayout extends StatelessWidget {
  const OnboardingStepLayout({
    super.key,
    required this.children,
    required this.actions,
  });

  final List<Widget> children;

  /// Bottom buttons, sharing the width.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.only(top: 36, bottom: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 52,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ),
          ),
        ),
        Row(
          spacing: 10,
          children: [
            for (final action in actions)
              Expanded(child: SizedBox(height: 52, child: action)),
          ],
        ),
      ],
    );
  }
}
