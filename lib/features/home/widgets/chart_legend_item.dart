import 'package:flutter/material.dart';

/// A square swatch and its series name.
class ChartLegendItem extends StatelessWidget {
  const ChartLegendItem(this.color, this.label, {super.key, this.border});

  final Color color;
  final String label;

  /// Around light swatches, like "Remaining".
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            border: border == null ? null : Border.all(color: border!),
          ),
        ),
        Flexible(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}
