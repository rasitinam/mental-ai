import 'package:flutter/material.dart';

/// Every color the app uses, resolved for the current [Brightness].
///
/// "Açık Ocak": a stone ground, ink for anything you press, and one soft
/// color per tab ([sun] Bugün, [sky] Sohbet, [peach] Hikayeler, [mint]
/// Yolum, [lilac] Ben). The tab colors are the same in both themes — only
/// the grounds, cards and text change — so a section keeps its identity in
/// the dark. Anything drawn on a tab color uses [onTint]. [ember] belongs to
/// the streak flame alone; [warning] stays reserved for crisis moments.
class AppPalette {
  final Color canvasTop;
  final Color canvasBottom;

  /// Cards and sheets.
  final Color glassFill;
  final Color glassBorder;
  final Color glassShadow;

  /// Primary buttons, selected chips, the send button.
  final Color accent;

  /// Text and icons drawn on top of [accent].
  final Color onAccent;
  final Color accentSoft;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color separator;
  final Color warning;
  final Color warningSoft;
  final Color surfaceMuted;

  /// Reserved for anything clinical.
  final Color accentAlt;

  final Color sun;
  final Color sky;
  final Color peach;
  final Color mint;
  final Color lilac;

  /// Text and icons on a tab color, in either theme.
  final Color onTint;
  final Color ember;

  /// Count badges (unread messages).
  final Color badge;

  /// The mood grid's scale: hardest day, neutral, best day.
  final Color moodLow;
  final Color moodMid;
  final Color moodHigh;

  const AppPalette({
    required this.canvasTop,
    required this.canvasBottom,
    required this.glassFill,
    required this.glassBorder,
    required this.glassShadow,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.separator,
    required this.warning,
    required this.warningSoft,
    required this.surfaceMuted,
    required this.accentAlt,
    required this.sun,
    required this.sky,
    required this.peach,
    required this.mint,
    required this.lilac,
    required this.onTint,
    required this.ember,
    required this.badge,
    required this.moodLow,
    required this.moodMid,
    required this.moodHigh,
  });

  static const light = AppPalette(
    canvasTop: Color(0xFFECEDE9),
    canvasBottom: Color(0xFFECEDE9),
    glassFill: Color(0xFFFBFBF8),
    glassBorder: Color(0xFFD9DBD4),
    glassShadow: Color(0x00000000),
    accent: Color(0xFF1C1E24),
    onAccent: Color(0xFFFBFBF8),
    accentSoft: Color(0xFFDCEBDF),
    textPrimary: Color(0xFF1C1E24),
    textSecondary: Color(0xFF4A4E57),
    textTertiary: Color(0xFF62666F),
    separator: Color(0xFFD9DBD4),
    warning: Color(0xFF9B3A2C),
    warningSoft: Color(0xFFF6E1DA),
    surfaceMuted: Color(0xFFE3E5DF),
    accentAlt: Color(0xFF3C5F92),
    sun: Color(0xFFF3DC8C),
    sky: Color(0xFFBFD3F2),
    peach: Color(0xFFF5C9AE),
    mint: Color(0xFFBDE3CC),
    lilac: Color(0xFFDCCDEB),
    onTint: Color(0xFF1C1E24),
    ember: Color(0xFFE2622F),
    badge: Color(0xFFB4412F),
    moodLow: Color(0xFFEBA98A),
    moodMid: Color(0xFFE4E2D6),
    moodHigh: Color(0xFF7FC49F),
  );

  static const dark = AppPalette(
    canvasTop: Color(0xFF14161C),
    canvasBottom: Color(0xFF14161C),
    glassFill: Color(0xFF20232B),
    glassBorder: Color(0xFF30343D),
    glassShadow: Color(0x00000000),
    accent: Color(0xFFD4D7DD),
    onAccent: Color(0xFF14161C),
    accentSoft: Color(0xFF2B3A33),
    textPrimary: Color(0xFFEEEDE8),
    textSecondary: Color(0xFFB7B9C0),
    textTertiary: Color(0xFF9A9DA6),
    separator: Color(0xFF30343D),
    warning: Color(0xFFE39A86),
    warningSoft: Color(0xFF3A2320),
    surfaceMuted: Color(0xFF2A2D36),
    accentAlt: Color(0xFFA9C1E8),
    sun: Color(0xFFF3DC8C),
    sky: Color(0xFFBFD3F2),
    peach: Color(0xFFF5C9AE),
    mint: Color(0xFFBDE3CC),
    lilac: Color(0xFFDCCDEB),
    onTint: Color(0xFF1C1E24),
    ember: Color(0xFFF07A4A),
    badge: Color(0xFFC44A36),
    moodLow: Color(0xFFEBA98A),
    moodMid: Color(0xFF3A3D46),
    moodHigh: Color(0xFF7FC49F),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  /// Ink or light text, whichever reads on [background].
  static Color inkOn(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.light
          ? light.textPrimary
          : dark.textPrimary;
}
