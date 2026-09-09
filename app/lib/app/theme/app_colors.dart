import 'package:flutter/material.dart';

/// Every color the app uses, resolved for the current [Brightness]. Two
/// distinct directions rather than one recolored twice: light is a cool
/// off-white with a moss-green accent and Instrument Sans; dark is
/// layered near-black surfaces with a periwinkle accent and Sora — see
/// `app/theme/app_theme.dart` for the font wiring. Both keep one warning
/// tone reserved for genuine crisis moments (the chat/home crisis
/// banners), separate from [surfaceMuted], which is for merely
/// informational notices (disclaimers, "here's how this works" boxes)
/// that shouldn't visually read as alarms.
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
  /// Neutral, low-emphasis surface for informational notices — distinct
  /// from [glassFill] (a card) and [warningSoft] (an active crisis
  /// alert), so a "this is a legal disclaimer" box doesn't read with the
  /// same visual urgency as "you may be in crisis."
  final Color surfaceMuted;

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
    required this.surfaceMuted,
  });

  static const light = AppPalette(
    canvasTop: Color(0xFFF5F6F2),
    canvasBottom: Color(0xFFEDEFE9),
    glassFill: Color(0xFFFFFFFF),
    glassBorder: Color(0x40E2E4DD),
    glassShadow: Color(0x0D191C18),
    accent: Color(0xFF5E7A57),
    accentSoft: Color(0xFFE8EEE4),
    textPrimary: Color(0xFF191C18),
    textSecondary: Color(0xFF666C63),
    textTertiary: Color(0xFF8A9086),
    separator: Color(0xFFE2E4DD),
    warning: Color(0xFF8E3B3B),
    warningSoft: Color(0xFFF3E8E4),
    surfaceMuted: Color(0xFFEDEFE9),
  );

  static const dark = AppPalette(
    canvasTop: Color(0xFF16191C),
    canvasBottom: Color(0xFF0E1013),
    glassFill: Color(0xFF1D2126),
    glassBorder: Color(0x14FFFFFF),
    glassShadow: Color(0x4D000000),
    accent: Color(0xFF93A2E6),
    accentSoft: Color(0x2E93A2E6),
    textPrimary: Color(0xFFECEDEF),
    textSecondary: Color(0xFF9AA0A8),
    textTertiary: Color(0xFF6C7A99),
    separator: Color(0x12FFFFFF),
    warning: Color(0xFFD98E7E),
    warningSoft: Color(0xFF2A1F1D),
    surfaceMuted: Color(0xFF1D2126),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
