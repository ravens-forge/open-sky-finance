import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Round value-axis bounds and grid step for a chart, about four steps apart
/// (0–4,000 by 1,000), so labels fall on round numbers.
@immutable
class ChartRange {
  factory ChartRange.around(double low, double high) {
    final span = math.max(high - low, 1.0);
    final magnitude = math
        .pow(10, (math.log(span / 4) / math.ln10).floor())
        .toDouble();
    final step = [
      1,
      2,
      2.5,
      5,
      10,
    ].map((f) => f * magnitude).firstWhere((s) => span / s <= 5);
    return ChartRange._(
      (low / step).floorToDouble() * step,
      (high / step).ceilToDouble() * step,
      step,
    );
  }

  const ChartRange._(this.min, this.max, this.step);

  final double min;
  final double max;
  final double step;
}
