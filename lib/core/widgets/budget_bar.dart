import 'package:flutter/material.dart';

import '../finance_colors.dart';

enum BudgetState {
  /// Under 80 %: `primary`.
  under,

  /// From 80 %: `secondary` (ochre).
  near,

  /// Exactly used up: ink.
  usedUp,

  /// Past 100 %: `expense` with an end tick.
  over,
}

BudgetState budgetState(int spentMicros, int budgetMicros) {
  if (spentMicros > budgetMicros) return BudgetState.over;
  if (budgetMicros <= 0) return BudgetState.under;
  if (spentMicros == budgetMicros) return BudgetState.usedUp;
  if (spentMicros * 5 >= budgetMicros * 4) return BudgetState.near;
  return BudgetState.under;
}

/// Square bar of spent against budget on `sunken`, with a tick at 80 %. The
/// overall bar passes [marker] (0–1) to show "today". The status text beside
/// it carries the meaning, so the bar itself is not announced.
class BudgetBar extends StatelessWidget {
  const BudgetBar({
    super.key,
    required this.spentMicros,
    required this.budgetMicros,
    this.height = 8,
    this.marker,
  });

  final int spentMicros;
  final int budgetMicros;
  final double height;
  final double? marker;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final finance = FinanceColors.of(context);
    final state = budgetState(spentMicros, budgetMicros);
    final fill = switch (state) {
      BudgetState.under => scheme.primary,
      BudgetState.near => scheme.secondary,
      BudgetState.usedUp => scheme.onSurface,
      BudgetState.over => finance.expense,
    };
    final ratio = budgetMicros <= 0
        ? (spentMicros > 0 ? 1.0 : 0.0)
        : (spentMicros / budgetMicros).clamp(0.0, 1.0);
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(double.infinity, height),
        painter: _BudgetPainter(
          ratio: ratio,
          fill: fill,
          track: finance.sunken,
          tick: scheme.surface,
          endTick: state == BudgetState.over ? finance.expense : null,
          marker: marker,
          markerColor: scheme.onSurface,
        ),
      ),
    );
  }
}

class _BudgetPainter extends CustomPainter {
  _BudgetPainter({
    required this.ratio,
    required this.fill,
    required this.track,
    required this.tick,
    required this.endTick,
    required this.marker,
    required this.markerColor,
  });

  final double ratio;
  final Color fill;
  final Color track;
  final Color tick;
  final Color? endTick;
  final double? marker;
  final Color markerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Mirror for right-to-left is not needed: en/es/fr are all LTR.
    canvas
      ..drawRect(Offset.zero & size, Paint()..color = track)
      ..drawRect(Rect.fromLTWH(0, 0, w * ratio, h), Paint()..color = fill)
      ..drawRect(Rect.fromLTWH(w * 0.8, 0, 1, h), Paint()..color = tick);
    if (endTick != null) {
      canvas.drawRect(
        Rect.fromLTWH(w - 2, -3, 2, h + 6),
        Paint()..color = endTick!,
      );
    }
    if (marker != null) {
      canvas.drawRect(
        Rect.fromLTWH(w * marker!.clamp(0.0, 1.0) - 1, -4, 2, h + 8),
        Paint()..color = markerColor,
      );
    }
  }

  @override
  bool shouldRepaint(_BudgetPainter old) =>
      old.ratio != ratio ||
      old.fill != fill ||
      old.track != track ||
      old.tick != tick ||
      old.endTick != endTick ||
      old.marker != marker ||
      old.markerColor != markerColor;
}
