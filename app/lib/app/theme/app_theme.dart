import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Builds a [ThemeData] from an [AppPalette]. The scaffold background is
/// transparent on purpose — [AppBackground] paints the canvas under every
/// screen.
class AppTheme {
  AppTheme._();

  /// Body styles get the body family; styles that already name a family
  /// (the display titles) keep it.
  static TextStyle _font(TextStyle style) => style.fontFamily != null
      ? style
      : style.copyWith(
          fontFamily: AppTypography.bodyFamily,
          fontFamilyFallback: const ['system-ui', 'sans-serif'],
        );

  static ThemeData _build(AppPalette palette, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: palette.mint,
      brightness: brightness,
      primary: palette.accent,
      onPrimary: palette.onAccent,
      surface: palette.glassFill,
      error: palette.warning,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: AppTypography.bodyFamily,
      scaffoldBackgroundColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.title3.copyWith(color: palette.textPrimary),
      ),
      textTheme: TextTheme(
        headlineMedium: _font(AppTypography.largeTitle.copyWith(color: palette.textPrimary)),
        headlineSmall: _font(AppTypography.title1.copyWith(color: palette.textPrimary)),
        titleLarge: _font(AppTypography.title2.copyWith(color: palette.textPrimary)),
        titleMedium: _font(AppTypography.headline.copyWith(color: palette.textPrimary)),
        bodyLarge: _font(AppTypography.body.copyWith(color: palette.textPrimary)),
        bodyMedium: _font(AppTypography.subheadline.copyWith(color: palette.textPrimary)),
        bodySmall: _font(AppTypography.footnote.copyWith(color: palette.textSecondary)),
        labelLarge: _font(AppTypography.label.copyWith(color: palette.textPrimary)),
        labelMedium: _font(AppTypography.footnote.copyWith(color: palette.textSecondary)),
        labelSmall: _font(AppTypography.caption.copyWith(color: palette.textTertiary)),
      ),
      dividerColor: palette.separator,
      iconTheme: IconThemeData(color: palette.textPrimary, size: 22),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: palette.textPrimary,
        selectionColor: palette.sky.withValues(alpha: 0.6),
        selectionHandleColor: palette.textPrimary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.accent,
        contentTextStyle: _font(AppTypography.label.copyWith(color: palette.onAccent)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.glassFill,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.textPrimary,
          minimumSize: const Size(44, 44),
          textStyle: _font(AppTypography.label),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.transparent),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: palette.textPrimary),
    );
  }

  static final ThemeData light = _build(AppPalette.light, Brightness.light);
  static final ThemeData dark = _build(AppPalette.dark, Brightness.dark);
}

/// Renders its subtree with the light theme. Tab-colored tiles look the same
/// in both themes, so what sits on them — ink buttons, chips, dark text —
/// has to as well.
class LightSurface extends StatelessWidget {
  final Widget child;
  const LightSurface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.light) return child;
    return Theme(data: AppTheme.light, child: child);
  }
}
