import 'package:flutter/material.dart';

@immutable
class FinanceColors extends ThemeExtension<FinanceColors> {
  const FinanceColors({
    required this.income,
    required this.expense,
    required this.transfer,
  });

  static const light = FinanceColors(
    income: Color(0xFF1F7A3E),
    expense: Color(0xFFB8391F),
    transfer: Color(0xFF2B5FAE),
  );

  static const dark = FinanceColors(
    income: Color(0xFF6FCF8A),
    expense: Color(0xFFFF8B6E),
    transfer: Color(0xFF86AEF0),
  );

  /// The theme's colours, or the defaults for its brightness.
  static FinanceColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<FinanceColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  final Color income;
  final Color expense;
  final Color transfer;

  @override
  FinanceColors copyWith({Color? income, Color? expense, Color? transfer}) =>
      FinanceColors(
        income: income ?? this.income,
        expense: expense ?? this.expense,
        transfer: transfer ?? this.transfer,
      );

  @override
  FinanceColors lerp(FinanceColors? other, double t) {
    if (other == null) return this;
    return FinanceColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      transfer: Color.lerp(transfer, other.transfer, t)!,
    );
  }
}
