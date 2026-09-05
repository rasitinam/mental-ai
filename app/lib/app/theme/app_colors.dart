import 'package:flutter/material.dart';

/// Every color the app uses, resolved for the current [Brightness]. One
/// restrained accent (a muted sage — fits a wellness app, avoids the
/// generic purple/blue "AI product" gradient), near-black/near-white text
/// per Apple's label-color convention, and glass tokens (fill/border/
/// shadow) tuned separately for light and dark since a translucent
/// surface needs a different alpha over a light background than over a
/// dark one to still read as "frosted glass" rather than "smudge".
class AppPalette {
  final Color canvasTop;
  final Color canvasBottom;
  final Color glassFill;
  final Color glassBorder;
  final Color glassShadow;
  final Color accent;
  final Color accentSoft;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color separator;
  final Color warning;
  final Color warningSoft;

  const AppPalette({
    required this.canvasTop,
    required this.canvasBottom,
    required this.glassFill,
    required this.glassBorder,
    required this.glassShadow,
    required this.accent,
    required this.accentSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.separator,
    required this.warning,
    required this.warningSoft,
  });

  static const light = AppPalette(
    canvasTop: Color(0xFFF6F4EF),
    canvasBottom: Color(0xFFEAE7DF),
    glassFill: Color(0x8CFFFFFF),
    glassBorder: Color(0xB3FFFFFF),
    glassShadow: Color(0x141C1C1E),
    accent: Color(0xFF3E6259),
    accentSoft: Color(0x1F3E6259),
    textPrimary: Color(0xFF1C1C1E),
    textSecondary: Color(0xFF6E6E73),
    textTertiary: Color(0xFF9A9A9E),
    separator: Color(0x1F1C1C1E),
    warning: Color(0xFFB5723B),
    warningSoft: Color(0x1FB5723B),
  );

  static const dark = AppPalette(
    canvasTop: Color(0xFF17181A),
    canvasBottom: Color(0xFF0B0C0D),
    glassFill: Color(0x14FFFFFF),
    glassBorder: Color(0x1FFFFFFF),
    glassShadow: Color(0x66000000),
    accent: Color(0xFF8DBBAC),
    accentSoft: Color(0x298DBBAC),
    textPrimary: Color(0xFFF2F2F5),
    textSecondary: Color(0xFFA6A6AB),
    textTertiary: Color(0xFF77777C),
    separator: Color(0x1FFFFFFF),
    warning: Color(0xFFE0A868),
    warningSoft: Color(0x33E0A868),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
