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
    final step = math.max(
      [
        1,
        2,
        2.5,
        5,
        10,
      ].map((f) => f * magnitude).firstWhere((s) => span / s <= 5),
      _resolution(math.max(low.abs(), high.abs())),
    );
    return ChartRange._(
      (low / step).floorToDouble() * step,
      (high / step).ceilToDouble() * step,
      step,
    );
  }

  const ChartRange._(this.min, this.max, this.step);

  /// The smallest step compact axis labels tell apart around [largest]: they
  /// keep three significant digits ("3.12K"), so 3,105 and 3,100 would both
  /// read "3.1K". Below 1,000 they show every digit.
  static double _resolution(double largest) {
    final digits = largest.floor().toString().length;
    return digits <= 3 ? 0 : math.pow(10, digits - 3).toDouble();
  }

  final double min;
  final double max;
  final double step;
}
