import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Builds a [ThemeData] from an [AppPalette]. The scaffold background is
/// left transparent on purpose — [AppBackground] paints the actual
/// canvas underneath every screen, so glass surfaces have something
/// consistent to sit on regardless of which screen is showing.
class AppTheme {
  AppTheme._();

  /// Every [AppTypography] style is family-less by design (see that
  /// file), so a `Text` widget without its own `fontFamily` inherits
  /// whichever one sits on the ambient `DefaultTextStyle` — which
  /// Flutter derives from here, `textTheme.bodyMedium`. Setting the
  /// family once, in this one helper, is what makes every existing
  /// `AppTypography.xxx.copyWith(color: ...)` call site across the app
  /// pick up the theme's font without needing to touch any of them.
  static TextStyle _font(String family, TextStyle style) =>
      style.copyWith(fontFamily: family, fontFamilyFallback: const ['system-ui']);

  static ThemeData _build(AppPalette palette, Brightness brightness, String fontFamily) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: palette.accent,
      brightness: brightness,
      primary: palette.accent,
    );
    TextStyle font(TextStyle style) => _font(fontFamily, style);

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
        titleTextStyle: font(AppTypography.title2.copyWith(color: palette.textPrimary)),
      ),
      textTheme: TextTheme(
        headlineMedium: font(AppTypography.largeTitle.copyWith(color: palette.textPrimary)),
        headlineSmall: font(AppTypography.title1.copyWith(color: palette.textPrimary)),
        titleLarge: font(AppTypography.title2.copyWith(color: palette.textPrimary)),
        titleMedium: font(AppTypography.headline.copyWith(color: palette.textPrimary)),
        bodyLarge: font(AppTypography.body.copyWith(color: palette.textPrimary)),
        bodyMedium: font(AppTypography.subheadline.copyWith(color: palette.textPrimary)),
        bodySmall: font(AppTypography.footnote.copyWith(color: palette.textSecondary)),
        labelLarge: font(AppTypography.headline.copyWith(color: palette.textPrimary)),
        labelMedium: font(AppTypography.footnote.copyWith(color: palette.textSecondary)),
        labelSmall: font(AppTypography.caption.copyWith(color: palette.textTertiary)),
      ),
      dividerColor: palette.separator,
      iconTheme: IconThemeData(color: palette.textSecondary, size: 22),
      textSelectionTheme: TextSelectionThemeData(cursorColor: palette.accent),
    );
  }

  static ThemeData get light => _build(AppPalette.light, Brightness.light, 'Instrument Sans');
  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark, 'Sora');
}
