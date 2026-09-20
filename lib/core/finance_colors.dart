import 'package:flutter/material.dart';

import '../data/enums/category_kind.dart';

@immutable
class FinanceColors extends ThemeExtension<FinanceColors> {
  const FinanceColors({
    required this.income,
    required this.expense,
    required this.transfer,
    required this.warning,
    required this.warningContainer,
    required this.expenseContainer,
    required this.sunken,
    required this.muted,
    required this.disabled,
    required this.chartSeries,
    required this.chartOther,
  });

  /// The app theme's colours (`lightTheme` / `darkTheme` carry them).
  static FinanceColors of(BuildContext context) =>
      Theme.of(context).extension<FinanceColors>()!;

  final Color income;
  final Color expense;
  final Color transfer;

  /// Warning text and icons ("Was due Sep 15"), on paper or [warningContainer].
  final Color warning;
  final Color warningContainer;

  /// Form error summary background.
  final Color expenseContainer;

  /// Progress tracks, info notes and loading placeholders.
  final Color sunken;

  /// Secondary text, captions, inactive tabs (≥ 4.5:1 on paper).
  final Color muted;

  /// Drag handles and disabled controls (not for text).
  final Color disabled;

  /// Chart series in order; "Remaining" and "Other" use [chartOther].
  final List<Color> chartSeries;
  final Color chartOther;

  /// Series colour for [index], wrapping around.
  Color series(int index) => chartSeries[index % chartSeries.length];

  @override
  FinanceColors copyWith() => this;

  @override
  FinanceColors lerp(FinanceColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return FinanceColors(
      income: l(income, other.income),
      expense: l(expense, other.expense),
      transfer: l(transfer, other.transfer),
      warning: l(warning, other.warning),
      warningContainer: l(warningContainer, other.warningContainer),
      expenseContainer: l(expenseContainer, other.expenseContainer),
      sunken: l(sunken, other.sunken),
      muted: l(muted, other.muted),
      disabled: l(disabled, other.disabled),
      chartSeries: [
        for (final (i, c) in chartSeries.indexed)
          l(c, other.chartSeries[i % other.chartSeries.length]),
      ],
      chartOther: l(chartOther, other.chartOther),
    );
  }
}

/// Income is green and expense is red; a category group is drawn in the
/// colour of its kind, and never by colour alone.
extension CategoryKindColor on CategoryKind {
  Color color(BuildContext context) => switch (this) {
    CategoryKind.income => FinanceColors.of(context).income,
    CategoryKind.expense => FinanceColors.of(context).expense,
  };

  IconData get icon => switch (this) {
    CategoryKind.income => Icons.arrow_upward,
    CategoryKind.expense => Icons.arrow_downward,
  };
}
