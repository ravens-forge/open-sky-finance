import 'package:flutter/material.dart';

import '../finance_colors.dart';

class PagePlaceholder extends StatelessWidget {
  const PagePlaceholder({super.key, required this.label, this.rows = 6});

  final String label;
  final int rows;

  @override
  Widget build(BuildContext context) {
    final sunken = FinanceColors.of(context).sunken;
    final line = Theme.of(context).colorScheme.outlineVariant;
    Widget bar(double width, double height) =>
        Container(width: width, height: height, color: sunken);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Semantics(
        label: label,
        liveRegion: true,
        container: true,
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      for (var i = 0; i < 3; i++)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 6,
                            children: [bar(56, 9), bar(88, 14)],
                          ),
                        ),
                    ],
                  ),
                ),
                Divider(color: line),
                const SizedBox(height: 16),
                bar(120, 14),
                const SizedBox(height: 12),
                for (var i = 0; i < rows; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: sunken,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, c) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 6,
                              children: [
                                bar(c.maxWidth * 0.62, 12),
                                bar(c.maxWidth * 0.4, 9),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        bar(60, 12),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
