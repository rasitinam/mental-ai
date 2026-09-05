import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Builds a [ThemeData] from an [AppPalette]. The scaffold background is
/// left transparent on purpose — [AppBackground] paints the actual
/// canvas underneath every screen, so glass surfaces have something
/// consistent to sit on regardless of which screen is showing.
class AppTheme {
  AppTheme._();

  static ThemeData _build(AppPalette palette, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: palette.accent,
      brightness: brightness,
      primary: palette.accent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.title2.copyWith(color: palette.textPrimary),
      ),
      textTheme: TextTheme(
        headlineMedium: AppTypography.largeTitle.copyWith(color: palette.textPrimary),
        headlineSmall: AppTypography.title1.copyWith(color: palette.textPrimary),
        titleLarge: AppTypography.title2.copyWith(color: palette.textPrimary),
        titleMedium: AppTypography.headline.copyWith(color: palette.textPrimary),
        bodyLarge: AppTypography.body.copyWith(color: palette.textPrimary),
        bodyMedium: AppTypography.subheadline.copyWith(color: palette.textPrimary),
        bodySmall: AppTypography.footnote.copyWith(color: palette.textSecondary),
        labelLarge: AppTypography.headline.copyWith(color: palette.textPrimary),
        labelMedium: AppTypography.footnote.copyWith(color: palette.textSecondary),
        labelSmall: AppTypography.caption.copyWith(color: palette.textTertiary),
      ),
      dividerColor: palette.separator,
      iconTheme: IconThemeData(color: palette.textSecondary, size: 22),
      textSelectionTheme: TextSelectionThemeData(cursorColor: palette.accent),
    );
  }

  static ThemeData get light => _build(AppPalette.light, Brightness.light);
  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);
}
