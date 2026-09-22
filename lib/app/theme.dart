import 'package:flutter/material.dart';

import '../core/finance_colors.dart';

// Shared by both themes: each theme's ink is the other's inverse surface.
const _ink = Color(0xFF1C1814);
const _inkDark = Color(0xFFF3EDE2);
const _pine = Color(0xFF0F5C4D);
const _pineDark = Color(0xFF5FC2A8);

// Light
const _paper = Color(0xFFFAF7F0);
const _surface = Color(0xFFFFFDF7);

// Dark
const _paperDark = Color(0xFF16130F);
const _surfaceDark = Color(0xFF211D17);

const _lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: _pine,
  onPrimary: _surface,
  primaryContainer: Color(0xFFD5EBE2),
  onPrimaryContainer: Color(0xFF0A3F35),
  secondary: Color(0xFFD18B1F),
  onSecondary: _ink,
  secondaryContainer: Color(0xFFF8E6C4),
  onSecondaryContainer: _ink,
  // Transfer
  tertiary: Color(0xFF2B5FAE),
  onTertiary: _surface,
  // Expense
  error: Color(0xFFB8391F),
  onError: _surface,
  errorContainer: Color(0xFFF8E0D8),
  onErrorContainer: _ink,
  // Paper is the page; the lighter "surface" token is every container.
  surface: _paper,
  onSurface: _ink,
  onSurfaceVariant: Color(0xFF4A4136),
  surfaceContainerLowest: _surface,
  surfaceContainerLow: _surface,
  surfaceContainer: _surface,
  surfaceContainerHigh: _surface,
  // Sunken: progress tracks, info notes, placeholders
  surfaceContainerHighest: Color(0xFFEAE2D1),
  // Ink rules and outline buttons; outlineVariant is the light row line.
  outline: _ink,
  outlineVariant: Color(0xFFE2D8C4),
  shadow: _ink,
  scrim: _ink,
  inverseSurface: _ink,
  onInverseSurface: _inkDark,
  inversePrimary: _pineDark,
  surfaceTint: Colors.transparent,
);

const _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: _pineDark,
  onPrimary: Color(0xFF062A22),
  primaryContainer: Color(0xFF16453B),
  onPrimaryContainer: Color(0xFFCBEDE1),
  secondary: Color(0xFFF0B550),
  onSecondary: _paperDark,
  secondaryContainer: Color(0xFF4A3510),
  onSecondaryContainer: _inkDark,
  tertiary: Color(0xFF86AEF0),
  onTertiary: _paperDark,
  error: Color(0xFFFF8B6E),
  onError: _paperDark,
  errorContainer: Color(0xFF4A2118),
  onErrorContainer: _inkDark,
  surface: _paperDark,
  onSurface: _inkDark,
  onSurfaceVariant: Color(0xFFD6CCBB),
  surfaceContainerLowest: _surfaceDark,
  surfaceContainerLow: _surfaceDark,
  surfaceContainer: _surfaceDark,
  surfaceContainerHigh: _surfaceDark,
  surfaceContainerHighest: Color(0xFF2B261F),
  outline: _inkDark,
  outlineVariant: Color(0xFF3A332A),
  shadow: Colors.black,
  scrim: Colors.black,
  inverseSurface: _inkDark,
  onInverseSurface: _ink,
  inversePrimary: _pine,
  surfaceTint: Colors.transparent,
);

/// [FinanceColors] from [c] plus the colours Material has no role for.
FinanceColors _finance(
  ColorScheme c, {
  required Color income,
  required Color warning,
  required Color warningContainer,
  required Color muted,
  required Color disabled,
  required List<Color> extraSeries,
}) => FinanceColors(
  income: income,
  expense: c.error,
  transfer: c.tertiary,
  warning: warning,
  warningContainer: warningContainer,
  expenseContainer: c.errorContainer,
  sunken: c.surfaceContainerHighest,
  muted: muted,
  disabled: disabled,
  chartSeries: [c.primary, c.secondary, c.error, c.tertiary, ...extraSeries],
  chartOther: c.outlineVariant,
);

final lightTheme = _theme(
  _lightScheme,
  _finance(
    _lightScheme,
    income: const Color(0xFF1F7A3E),
    warning: const Color(0xFF9A5B00),
    warningContainer: const Color(0xFFFBE7C2),
    muted: const Color(0xFF6A5F51),
    disabled: const Color(0xFF9A8F7E),
    extraSeries: const [Color(0xFF7D5BA6), Color(0xFF3F9C8C)],
  ),
);

final darkTheme = _theme(
  _darkScheme,
  _finance(
    _darkScheme,
    income: const Color(0xFF6FCF8A),
    warning: const Color(0xFFF2C15C),
    warningContainer: const Color(0xFF3D2A08),
    muted: const Color(0xFFB3A896),
    disabled: const Color(0xFF7D7263),
    extraSeries: const [Color(0xFFB89AE0), Color(0xFF6FC7B8)],
  ),
);

const serif = 'Newsreader';
const sans = 'PublicSans';

/// Lining tabular figures everywhere, so amounts line up.
const _figures = [FontFeature.tabularFigures(), FontFeature.liningFigures()];

TextStyle _text(
  String family,
  double size,
  FontWeight weight,
  Color color, {
  double? spacing,
  double? height,
}) => TextStyle(
  fontFamily: family,
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: spacing ?? 0,
  height: height,
  fontFeatures: _figures,
);

TextTheme _textTheme(ColorScheme c, FinanceColors f) {
  final ink = c.onSurface;
  return TextTheme(
    displayLarge: _text(serif, 56, FontWeight.w500, ink, height: 1.1),
    displayMedium: _text(serif, 44, FontWeight.w500, ink, height: 1.1),
    headlineLarge: _text(serif, 30, FontWeight.w500, ink, height: 1.2),
    headlineMedium: _text(serif, 28, FontWeight.w500, ink, height: 1.2),
    headlineSmall: _text(serif, 24, FontWeight.w500, ink, height: 1.25),
    titleLarge: _text(serif, 22, FontWeight.w500, ink, height: 1.25),
    titleMedium: _text(serif, 18, FontWeight.w500, ink, height: 1.3),
    titleSmall: _text(sans, 14, FontWeight.w500, ink),
    bodyLarge: _text(sans, 15, FontWeight.w400, ink, height: 1.4),
    bodyMedium: _text(sans, 14, FontWeight.w400, ink, height: 1.4),
    bodySmall: _text(sans, 12, FontWeight.w400, f.muted, height: 1.35),
    labelLarge: _text(sans, 15, FontWeight.w600, ink),
    labelMedium: _text(sans, 12, FontWeight.w600, f.muted, spacing: 1.44),
    labelSmall: _text(sans, 11, FontWeight.w600, f.muted, spacing: 1.32),
  );
}

/// Names for the Ledger type roles.
extension LedgerTextTheme on TextTheme {
  /// Net worth, editor amount (44–56).
  TextStyle get hero => displayMedium!;

  /// Drawer page titles.
  TextStyle get pageTitle => headlineMedium!;

  /// Serif section titles, dialog and sheet titles.
  TextStyle get sectionTitle => headlineSmall!;

  /// Uppercase tracked label; pass text already upper-cased for the locale.
  TextStyle get eyebrow => labelMedium!;

  TextStyle get rowTitle => bodyLarge!.copyWith(fontWeight: FontWeight.w500);
  TextStyle get rowSubtitle => bodySmall!;
  TextStyle get rowAmount => bodyLarge!.copyWith(fontWeight: FontWeight.w600);
  TextStyle get tab => titleSmall!;

  /// Serif italic value on the last point of a line chart.
  TextStyle get chartValue => titleMedium!.copyWith(
    fontSize: 13,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w400,
  );

  /// Serif figures of the Home summary.
  TextStyle get summaryFigure => headlineMedium!.copyWith(height: 1.1);
}

const _pill = StadiumBorder();
const _square = RoundedRectangleBorder();

ThemeData _theme(ColorScheme c, FinanceColors f) {
  final text = _textTheme(c, f);
  // Sheets and dialogs are square with a 2 px ink rule on top.
  final inkTop = Border(top: BorderSide(color: c.outline, width: 2));
  final line = BorderSide(color: c.outlineVariant);
  final buttonText = text.labelLarge;
  const buttonSize = Size(64, 48);
  const buttonPadding = EdgeInsets.symmetric(horizontal: 20);

  return ThemeData(
    colorScheme: c,
    fontFamily: sans,
    textTheme: text,
    scaffoldBackgroundColor: c.surface,
    extensions: [f],
    appBarTheme: AppBarTheme(
      backgroundColor: c.surface,
      foregroundColor: c.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 60,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: c.primary,
      unselectedLabelColor: f.muted,
      labelStyle: text.tab.copyWith(fontWeight: FontWeight.w700),
      unselectedLabelStyle: text.tab,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: c.primary, width: 3),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: c.outline,
      dividerHeight: 2,
      tabAlignment: TabAlignment.start,
      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: _pill,
        minimumSize: buttonSize,
        padding: buttonPadding,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: _pill,
        minimumSize: buttonSize,
        padding: buttonPadding,
        textStyle: buttonText,
        foregroundColor: c.onSurface,
        side: BorderSide(color: c.outline),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: _pill,
        minimumSize: buttonSize,
        textStyle: buttonText,
        foregroundColor: c.onSurface,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.primary,
      foregroundColor: c.onPrimary,
      shape: _pill,
      extendedTextStyle: buttonText,
      extendedSizeConstraints: const BoxConstraints.tightFor(height: 56),
    ),
    chipTheme: ChipThemeData(
      shape: _pill,
      side: BorderSide(color: c.outline),
      backgroundColor: Colors.transparent,
      labelStyle: text.bodyMedium!.copyWith(fontWeight: FontWeight.w500),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: inkTop,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      barrierColor: c.scrim.withValues(alpha: 0.45),
      titleTextStyle: text.sectionTitle,
      contentTextStyle: text.bodyLarge!.copyWith(color: c.onSurfaceVariant),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surfaceContainerLow,
      modalBackgroundColor: c.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: inkTop,
      showDragHandle: true,
      dragHandleColor: f.disabled,
      dragHandleSize: const Size(36, 4),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: c.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: _square,
      endShape: _square,
      width: 312,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.inverseSurface,
      contentTextStyle: text.bodyMedium!.copyWith(color: c.onInverseSurface),
      actionTextColor: c.inversePrimary,
      behavior: SnackBarBehavior.floating,
      shape: _square,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: UnderlineInputBorder(borderSide: line),
      enabledBorder: UnderlineInputBorder(borderSide: line),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: c.primary, width: 2),
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: f.expense, width: 2),
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: f.expense, width: 2),
      ),
      labelStyle: text.bodySmall,
      hintStyle: text.bodyLarge!.copyWith(color: f.disabled),
      errorStyle: text.bodySmall!.copyWith(
        color: f.expense,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: c.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      minTileHeight: 56,
      iconColor: f.muted,
      titleTextStyle: text.rowTitle,
      subtitleTextStyle: text.rowSubtitle,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.primary,
      linearTrackColor: c.outlineVariant,
      linearMinHeight: 2,
      borderRadius: BorderRadius.zero,
    ),
    cardTheme: const CardThemeData(shape: _square, elevation: 0),
    popupMenuTheme: PopupMenuThemeData(
      shape: _square,
      color: c.surfaceContainer,
      surfaceTintColor: Colors.transparent,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: c.inverseSurface),
      textStyle: text.bodySmall!.copyWith(color: c.onInverseSurface),
    ),
  );
}
